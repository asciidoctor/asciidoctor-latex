module.exports = Builder;

var async = require('async');
var fs = require('fs');
var path = require('path');
var https = require('https');
var http = require('http');
var OpalCompiler = require('bestikk-opal-compiler');
var log = require('bestikk-log');
var bfs = require('bestikk-fs');

function Builder () {
  this.asciidoctorCoreVersion = '1.5.5';
  this.asciidoctorJsVersion = '1.5.5-3';
  this.htmlEntitiesVersion = '4.3.3';
}

Builder.prototype.build = function (callback) {
  if (process.env.SKIP_BUILD) {
    log.info('SKIP_BUILD environment variable is true, skipping "build" task');
    callback();
    return;
  }
  if (process.env.DRY_RUN) {
    log.debug('build');
    callback();
    return;
  }
  var builder = this;
  var start = process.hrtime();

  async.series([
    function (callback) { builder.clean(callback); }, // clean
    function (callback) { builder.downloadDependencies(callback); }, // download dependencies
    function (callback) { builder.compile(callback); }, // compile
    function (callback) { builder.copyToDist(callback); } // copy to dist
  ], function () {
    log.success('Done in ' + process.hrtime(start)[0] + 's');
    typeof callback === 'function' && callback();
  });
};

Builder.prototype.clean = function (callback) {
  log.task('clean');
  this.removeBuildDirSync(); // remove build directory
  callback();
};

Builder.prototype.downloadDependencies = function (callback) {
  log.task('download dependencies');

  var builder = this;
  async.series([
    function (callback) { builder.getContentFromURL('https://codeload.github.com/asciidoctor/asciidoctor/tar.gz/v' + builder.asciidoctorCoreVersion, 'build/asciidoctor.tar.gz', callback); },
    function (callback) { builder.getContentFromURL('https://codeload.github.com/asciidoctor/asciidoctor.js/tar.gz/v' + builder.asciidoctorJsVersion, 'build/asciidoctor.js.tar.gz', callback); },
    function (callback) { builder.getContentFromURL('https://codeload.github.com/threedaymonk/htmlentities/tar.gz/v' + builder.htmlEntitiesVersion, 'build/htmlentities.tar.gz', callback); },
    function (callback) { bfs.untar('build/asciidoctor.tar.gz', 'asciidoctor', 'build', callback); },
    function (callback) { bfs.untar('build/asciidoctor.js.tar.gz', 'asciidoctor.js', 'build', callback); },
    function (callback) { bfs.untar('build/htmlentities.tar.gz', 'htmlentities', 'build', callback); }
  ], function () {
    typeof callback === 'function' && callback();
  });
};

Builder.prototype.removeBuildDirSync = function () {
  log.debug('remove build directory');
  bfs.removeSync('build');
  bfs.mkdirsSync('build');
};

Builder.prototype.copyToDist = function (callback) {
  var builder = this;

  log.task('copy to dist/');
  bfs.removeSync('dist');
  bfs.mkdirsSync('dist');
  bfs.copySync('build/asciidoctor-latex.js', 'dist/main.js');
  typeof callback === 'function' && callback();
};

Builder.prototype.getContentFromURL = function (source, target, callback) {
  log.transform('get', source, target);
  var targetStream = fs.createWriteStream(target);
  var downloadModule;
  // startWith alternative
  if (source.lastIndexOf('https', 0) === 0) {
    downloadModule = https;
  } else {
    downloadModule = http;
  }
  downloadModule.get(source, function (response) {
    response.pipe(targetStream);
    targetStream.on('finish', function () {
      targetStream.close(callback);
    });
  });
};

Builder.prototype.compile = function (callback) {
  var opalCompiler = new OpalCompiler({dynamicRequireLevel: 'ignore', defaultPaths: ['build/asciidoctor/lib', 'build/asciidoctor.js/lib']});

  bfs.mkdirsSync('build');

  log.task('compile latex');
  opalCompiler.compile('asciidoctor-latex', 'build/asciidoctor-latex.js', ['lib', 'build/htmlentities/lib']);
  
  callback();
};

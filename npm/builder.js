module.exports = Builder;

const async = require('async');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const OpalCompiler = require('bestikk-opal-compiler');
const log = require('bestikk-log');
const bfs = require('bestikk-fs');

function Builder () {
  this.asciidoctorCoreVersion = '1.5.5';
  this.asciidoctorJsVersion = '1.5.5';
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
  const builder = this;
  const start = process.hrtime();

  async.series([
    callback => builder.clean(callback), // clean
    callback => builder.downloadDependencies(callback), // download dependencies
    callback => builder.compile(callback), // compile
    callback => builder.generateUMD(callback), // compile
    callback => builder.copyToDist(callback) // copy to dist
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

  const builder = this;
  async.series([
    callback => builder.getContentFromURL('https://codeload.github.com/asciidoctor/asciidoctor/tar.gz/v' + builder.asciidoctorCoreVersion, 'build/asciidoctor.tar.gz', callback),
    callback => builder.getContentFromURL('https://codeload.github.com/asciidoctor/asciidoctor.js/tar.gz/v' + builder.asciidoctorJsVersion, 'build/asciidoctor.js.tar.gz', callback),
    callback => builder.getContentFromURL('https://codeload.github.com/threedaymonk/htmlentities/tar.gz/v' + builder.htmlEntitiesVersion, 'build/htmlentities.tar.gz', callback),
    callback => bfs.untar('build/asciidoctor.tar.gz', 'asciidoctor', 'build', callback),
    callback => bfs.untar('build/asciidoctor.js.tar.gz', 'asciidoctor.js', 'build', callback),
    callback => bfs.untar('build/htmlentities.tar.gz', 'htmlentities', 'build', callback)
  ], () => {
    typeof callback === 'function' && callback();
  });
};

Builder.prototype.removeBuildDirSync = function () {
  log.debug('remove build directory');
  bfs.removeSync('build');
  bfs.mkdirsSync('build');
};

Builder.prototype.copyToDist = function (callback) {
  const builder = this;

  log.task('copy to dist/');
  bfs.removeSync('dist');
  bfs.mkdirsSync('dist');
  bfs.copySync('build/asciidoctor-latex.js', 'dist/main.js');
  typeof callback === 'function' && callback();
};

Builder.prototype.getContentFromURL = function (source, target, callback) {
  log.transform('get', source, target);
  const targetStream = fs.createWriteStream(target);
  let downloadModule;
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

const parseTemplate = function (templateFile, templateModel) {
  return fs.readFileSync(templateFile, 'utf8')
    .replace(/\r\n/g, '\n')
    .split('\n')
    .map(line => {
      if(line in templateModel){
        return templateModel[line];
      } else {
        return line;
      }
    })
    .join('\n');
};

Builder.prototype.generateUMD = function (callback) {
  log.task('generate UMD');

  const templateModel = {
    '//#{opalCode}': fs.readFileSync('node_modules/opal-runtime/src/opal.js', 'utf8'),
    '//#{asciidoctorLatexCode}': fs.readFileSync('build/asciidoctor-latex-lib.js', 'utf8')
  };
  const content = parseTemplate('src/template-asciidoctor-latex.js', templateModel);
  fs.writeFileSync('build/asciidoctor-latex.js', content, 'utf8');
  callback();
};

Builder.prototype.compile = function (callback) {
  const opalCompiler = new OpalCompiler({dynamicRequireLevel: 'ignore', defaultPaths: ['build/asciidoctor/lib', 'build/asciidoctor.js/lib']});

  bfs.mkdirsSync('build');

  log.task('compile latex');
  opalCompiler.compile('asciidoctor-latex', 'build/asciidoctor-latex-lib.js', ['lib', 'build/htmlentities/lib']);
  callback();
};

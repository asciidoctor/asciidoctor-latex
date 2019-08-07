# -*- encoding: utf-8 -*-
require File.expand_path('../lib/asciidoctor/latex/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'asciidoctor-latex'
  s.version       = Asciidoctor::LaTeX::VERSION
  s.authors       = ['James Carlson', 'Jakub Jirutka', 'Dan Allen']
  s.email         = 'jxxcarlson@mac.com'
  s.homepage      = 'https://github.com/asciidoctor/asciidoctor-latex'
  s.license       = 'MIT'

  s.summary       = 'Converts AsciiDoc documents to LaTeX, provides LaTeX extensions to Asciidoc'
  s.description   = 'An extension for Asciidoctor that converts AsciiDoc documents to LaTeX and provides LaTeX extensions to Asciidoc.'

  begin
    s.files       = `git ls-files -z -- */* {CHANGELOG,LICENSE,manual,Rakefile,README}*`.split "\0"
  rescue
    s.files       = Dir['**/*']
  end
  s.executables   = s.files.grep(/^bin\//) { |f| File.basename(f) }
  s.test_files    = s.files.grep(/^(test|spec|features)\//)
  s.require_paths = ['lib']

  s.has_rdoc      = 'yard'

  s.required_ruby_version = '>= 2.0'

  s.add_runtime_dependency 'asciidoctor', '>= 1.5.2'
  s.add_runtime_dependency 'opal', '~> 0.6.3'
  s.add_runtime_dependency 'htmlentities', '~> 4.3'

  # specified in the Gemfile for now
  #s.add_development_dependency 'asciidoctor-doctest', '~> 1.5.2.dev'

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'yard', '~> 0.8'
end

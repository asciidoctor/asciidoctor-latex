# -*- encoding: utf-8 -*-
require File.expand_path('lib/asciidoctor-latex/version', File.dirname(__FILE__))

Gem::Specification.new do |s| 
  s.name = 'asciidoctor-latex'
  s.version = Asciidoctor::LaTeX::VERSION

  s.summary = 'Converts AsciiDoc documents to LaTeX'
  s.description = <<-EOS
An extension for Asciidoctor that converts AsciiDoc documents to LaTeX.
  EOS

  s.authors = ['James Carlson', 'Dan Allen']
  s.email = 'jxxcarlson@mac.com'
  s.homepage = 'https://github.com/asciidoctor/asciidoctor-latex'
  s.license = 'MIT'

  s.required_ruby_version = '>= 1.9'

  begin
    s.files = `git ls-files -z -- */* {README.adoc,LICENSE.adoc,Rakefile}`.split "\0"
  rescue
    s.files = Dir['**/*']
  end

  s.executables = %w(asciidoctor-latex)
  s.test_files = s.files.grep(/^(?:test|spec|feature)\/.*$/)
  s.require_paths = %w(lib)

  s.has_rdoc = true
  s.rdoc_options = %(--charset=UTF-8 --title="Asciidoctor LaTeX" --main=README.adoc -ri)
  s.extra_rdoc_files = %w(README.adoc LICENSE.adoc)

  s.add_development_dependency 'rake', '~> 10.0'
  #s.add_development_dependency 'rdoc', '~> 4.1.0'

  s.add_runtime_dependency 'asciidoctor', '~> 1.5.0', '>= 1.5.0'
end

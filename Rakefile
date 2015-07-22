# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'rake/clean'
require 'bundler/gem_tasks'

begin
  require 'yard'
  # options are defined in .yardopts
  YARD::Rake::YardocTask.new

  task :doc => :yard
rescue LoadError => e
  warn "#{e.path} is not available"
end

begin
  require 'asciidoctor-doctest'
  require 'asciidoctor-latex'
  require 'rake/testtask'

  namespace :doctest do
    Rake::TestTask.new(:latex) do |t|
      t.description = 'Run integration tests for LaTeX output.'
      t.pattern = 'test/latex_test.rb'
      t.libs << 'test'
    end

    Rake::TestTask.new(:html) do |t|
      t.description = 'Run integration tests for HTML output.'
      t.pattern = 'test/html_test.rb'
      t.libs << 'test'
    end
  end

  task :doctest => [ 'doctest:latex', 'doctest:html' ]
  task :test    => :doctest
  task :default => :test

  namespace :generate do

    DocTest::GeneratorTask.new(:latex) do |t|
      t.converter_opts[:backend_name] = :latex
      t.output_suite = DocTest::Latex::ExamplesSuite.new(examples_path: 'test/examples/tex')
      t.examples_path.unshift 'test/examples/adoc'  # extra input examples
    end

    DocTest::GeneratorTask.new(:html) do |t|
      t.converter_opts[:backend_name] = :html
      t.output_suite = DocTest::HTML::ExamplesSuite.new(examples_path: 'test/examples/html')
      t.examples_path = ['test/examples/asciidoc-html']  # input examples
    end
  end
rescue LoadError => e
  warn "#{e.path} is not available"
end

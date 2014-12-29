# -*- encoding: utf-8 -*-
require 'rake/clean'
require 'rake/testtask'
require 'bundler/gem_tasks'

Rake::TestTask.new(:doctest) do |t|
  t.description = 'Run integration tests (DocTest)'
  t.pattern = 'test/templates_test.rb'
  t.libs << 'test'
end

begin
  require 'yard'
  # options are defined in .yardopts
  YARD::Rake::YardocTask.new
rescue LoadError => e
  warn "#{e.path} is not available"
end

begin
  require 'asciidoctor-doctest'

  DocTest::GeneratorTask.new(:generate) do |t|
    t.output_suite = DocTest::HTML::ExamplesSuite.new(examples_path: 'test/examples/tex')
    t.converter_opts[:backend_name] = :latex
    t.examples_path.unshift 'test/examples/adoc'
  end
rescue LoadError => e
  warn "#{e.path} is not available"
end

task :test => :doctest
task :doc => :yard
task :default => :test

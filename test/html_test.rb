require 'test_helper'

DocTest.examples_path.unshift 'test/examples/html', 'test/examples/asciidoc-html'

class HtmlTest < DocTest::Test
  converter_opts backend_name: 'html', dialect: 'latex'
  html_suite = DocTest::HTML::ExamplesSuite.new paragraph_xpath: './div/p/node()'
  generate_tests! html_suite
end

require 'test_helper'

DocTest.examples_path = ['test/examples/html', 'test/examples/asciidoc-html']

class HtmlTest < DocTest::Test
  converter_opts backend_name: 'html', dialect: 'latex'
  generate_tests! DocTest::HTML::ExamplesSuite
end

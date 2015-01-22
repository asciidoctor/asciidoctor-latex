require 'test_helper'

DocTest.examples_path.unshift 'test/examples/tex', 'test/examples/adoc'

class LatexTest < DocTest::Test
  converter_opts backend_name: 'latex'
  generate_tests! DocTest::Latex::ExamplesSuite
end

require 'test_helper'

class LatexTest < DocTest::Test
  converter_opts backend_name: 'latex'
  generate_tests! DocTest::Latex::ExamplesSuite
end

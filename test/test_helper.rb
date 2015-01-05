require 'asciidoctor/doctest'
require 'asciidoctor/latex'
require 'minitest/autorun'
require 'minitest/rg'

# extra input examples (optional)
DocTest.examples_path.unshift 'test/examples/adoc'

# output examples
DocTest.examples_path.unshift 'test/examples/tex'

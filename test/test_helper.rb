require 'asciidoctor/doctest'
require 'minitest/autorun'

# used to colorize output
require 'minitest/rg'

# needed if you're testing templates-based backend
# require 'tilt'

# extra input examples (optional)
DocTest.examples_path.unshift 'test/examples/adoc'

# output examples
# DocTest.examples_path.unshift 'test/examples/html'

# output examples
DocTest.examples_path.unshift 'test/examples/tex'

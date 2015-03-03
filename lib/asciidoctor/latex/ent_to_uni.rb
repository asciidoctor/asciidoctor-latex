require 'asciidoctor'
require 'asciidoctor/extensions'
require 'htmlentities'

# Map HTML entties to their unicode equivalents
# before running LaTeX
#
module Asciidoctor::LaTeX
  class EntToUni < Asciidoctor::Extensions::Postprocessor

    def process document, output
      coder = HTMLEntities.new
      coder.decode output
    end

  end
end

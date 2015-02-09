require 'asciidoctor'
require 'asciidoctor/extensions'

module Asciidoctor::LaTeX
  # Map DOLLOD to $
  class Dollar < Asciidoctor::Extensions::Postprocessor

    def process document, output
      output = output.gsub('DOLLOD', '$')
    end

  end
end

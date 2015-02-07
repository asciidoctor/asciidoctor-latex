require 'asciidoctor'
require 'asciidoctor/extensions'

module Asciidoctor::LaTeX
  # Map @@DOLLAR: to \$
  class EscapeDollar < Asciidoctor::Extensions::Postprocessor

    def process document, output
      output = output.gsub('DOLLOD', '\$')
    end

  end
end

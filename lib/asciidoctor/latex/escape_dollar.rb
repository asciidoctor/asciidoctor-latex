require 'asciidoctor'
require 'asciidoctor/extensions'

module Asciidoctor::LaTeX
  # Map @@DOLLAR: to \$
  class EscapeDollar < Asciidoctor::Extensions::Postprocessor

    def process document, output
      output = output.gsub('\DOLLOD', '\$') if document.basebackend? 'html'
      output = output.gsub('CHEMRIGHTARROW','->').gsub('CHEMLEFTARROW','<-').gsub('CHEMLEFTRIGHTARROW','<-->') if document.basebackend? 'tex'
      output
    end

  end
end

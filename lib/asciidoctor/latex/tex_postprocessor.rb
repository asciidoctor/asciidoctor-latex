require 'asciidoctor'
require 'asciidoctor/extensions'

# a postprocessor to map the nonsense
# string 'DOLLOD' back to '$'
#
# This is used in for the LaTeX backend
# in conjunction with the code
# in 'tex_preprocessor' which maps '\$' to
# 'DOLLOD'
#
# There should be a better solution to the
# vexing proble of dealing with both $ ... $
# for mathematics and '\$' for currency. But
# this works and wil have to do for now.
#
# @jirutka: Advice?
#
module Asciidoctor::LaTeX
  # Map @@DOLLAR: to \$
  class TexPostprocessor < Asciidoctor::Extensions::Postprocessor

    def process document, output
      output = output.gsub('\DOLLOD', '\$') if document.basebackend? 'html'
      output = output.gsub('CHEMRIGHTARROW','->').gsub('CHEMLEFTARROW','<-').gsub('CHEMLEFTRIGHTARROW','<-->') if document.basebackend? 'tex'
      output
    end

  end
end

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
      output = output.gsub('DOLLOD', '\$')
      output = output.gsub('CHEMRIGHTARROW','->').gsub('CHEMLEFTARROW','<-').gsub('CHEMLEFTRIGHTARROW','<-->')
      output.gsub('!!!BACKSLASH', '\\')
    end

  end

  class HTMLPostprocessor < Asciidoctor::Extensions::Postprocessor

    def process document, output
      output = output.gsub('\DOLLOD', '\$')
      # match_data = output.match /%%(.*)%%/
      # if match_data
      #  output = output.gsub(match_data[0], match_data[1])
      # end
      output = output.gsub('DOLLOD', '$')
      output.gsub('!!!BACKSLASH', '\\')
    end

  end
end

require 'asciidoctor'
require 'asciidoctor/extensions'

# Map $ ... $ to \(..\) before
# running Asciidoctor, and map
# '\$' to 'DOLLOD'.  The latter
# will be mapped back to '$'
# for the HTML backend by the
# postprocessor in 'dollar.rb' and
# to '\$' by the postprocessor
# in 'escape_dollar.rb'
#
# The remaining substitutions will
# be eliminated when I edit the
# relevant source files on noteshare.

module Asciidoctor::LaTeX
  class TeXPreprocessor < Asciidoctor::Extensions::Preprocessor

    # Map $...$ to stem:[...]
    # TEX_DOLLAR_RX = /(^|\s|\()\$(.*?)\$($|\s|\)|,|\.)/
    # TEX_DOLLAR_SUB = '\1latexmath:[\2]\3'
    # TEX_DOLLAR_SUB = '\1\\\(\2\\\)\3'

    TEX_DOLLAR_RX = /\$(.*?)\$/
    TEX_DOLLAR_SUB = '\\\(\1\\\)'
    TEX_DOLLAR_SUB2 = '+\\\(\1\\\)+'


    def process document, reader
      return reader if reader.eof?
      replacement_lines = reader.read_lines.map do |line|
        # (line.include? '$') ? (line.gsub TEX_DOLLAR_RX, TEX_DOLLAR_SUB) : line
        if line.include? '<-->' and document.basebackend? 'tex'
          line = line.gsub('<-->', 'CHEMLEFTRIGHTARROW')
        end
        if line.include? '->' and document.basebackend? 'tex'
          line = line.gsub('->', 'CHEMRIGHTARROW')
        end
        if line.include? '<-' and document.basebackend? 'tex'
          line = line.gsub('<-', 'CHEMLEFTARROW')
        end
        if line.include? '\$' and document.basebackend? 'html'
          line = line.gsub '\$', 'DOLLOD'
        end
        if line.include? '%' and document.basebackend? 'tex'
          line = line.gsub '%', '\%'
        end
        if line.include? '$'
          line = line.gsub TEX_DOLLAR_RX, TEX_DOLLAR_SUB2
        end
        if line.include? '^\\['
          line = line.gsub '\\[', '+\\['
        end
        if line.include? '^\\]'
          line = line.gsub '\\]', '\\]+'
        end
        line
      end
      reader.unshift_lines replacement_lines
      reader
    end

  end
end

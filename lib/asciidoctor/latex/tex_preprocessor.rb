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
    TEX_DOLLAR_SUB = 'pass:[\\\(\1\\\)]'


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

        # SPECIAL CHARACTER SUBSTITUTIONS
        if line.include? '\\&' and document.basebackend? 'html'
          line = line.gsub '\\&', 'ESCAMPERSAND'
        end
        if line.include? '\\_' and document.basebackend? 'html'
          line = line.gsub '\\_', 'ESCUNDERSCORE'
        end
        if line.include? '\\' and document.basebackend? 'html'
          line = line.gsub '\\$', 'ESCDOLLAR'
        end
        # It is important the previous transformation
        # come before the next one
        if line.include? '$'
          line = line.gsub TEX_DOLLAR_RX, TEX_DOLLAR_SUB
        end

        # protect math, e.g., (a^2)^3 from Asciidoc subsitutions:
        if line =~ /^\\\[/
          line = line.gsub '\\[', "+++\n\\["
          # line = line.gsub /^\\\[/, '+\\]'
          # line = line.gsub '\\[', '\\['
        end
        if line =~ /^\\\]/
          line = line.gsub '\\]', "\\]\n+++\n"
          # line = line.gsub /'^\\\]/, '\\]+'
          # line = line.gsub '\\]', '\\]+'
        end
        # if line =~ /\[env\..*?\]/
        #  m = line.match /(\[env\..*?)\]/
        #  line = line.gsub m[1], m[1]+',subs=none'
        # end
        # if line =~ /\&/
        #  line = line.gsub('&', '\\\&')
        # en
        # We do need to make this substitution, but ONLY ouutside
        # of mathematical text.
        # Please $FIXME!
        #
        # We would like to ensure that underscores in names,
        # e.g., MACRO_NAME, do not cause LaTeX bugs. However,
        # the code below introduces a more serious bug: expressions
        # lik4 $\int_0^1 x^n dx$ are mapped to  $\int\_0^1 x^n dx$.
        # I'm not sure this problem can be solved using regex's:
        # we need to apply a substitution to a line when there is a match
        # with '_' AND the word containing the '_' IS NOT in any enclosng
        # $ ... $ or \[ ... \].  If we had a parser that would recognize
        # $ ... $ and \[ ... \] and build them into the AST as nodes,
        # then there would be an easy solution.  This issue may
        # have to wait.
        # if line =~ /_/
        #  line = line.gsub /_/, '\_'
        # end
        line
      end
      reader.unshift_lines replacement_lines
      reader
    end

  end
end

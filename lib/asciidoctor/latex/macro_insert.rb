require 'asciidoctor'
require 'asciidoctor/extensions'

module Asciidoctor::LaTeX


  # Prepend lines (in this case tex macro definitions) to a document


  class MacroInsert < Asciidoctor::Extensions::Preprocessor

    def putline line
      @@line_array += [line, ""]
    end

    def process document, reader

      file_contents = IO.read('macros.tex')
      if file_contents == nil
        file_contents = IO.read('public/macros.tex')
      end
      if file_contents
        warn "In MacroInsert, file_contents: #{file_contents.length} chars read".yellow if $VERBOSE
      else
        warn "In MacroInsert, file_contents: NIL".yellow if $VERBOSE
      end

      @@line_array = []

      return reader if reader.eof?

      putline '++++'
      putline "<div class='hide'>"
      putline '\('
      lines = file_contents.split("\n")
      lines.each do |line|
        putline line
      end

      putline '\)'
      putline '</div>'
      putline '++++'

      reader.unshift_lines @@line_array
      reader
    end

  end
end

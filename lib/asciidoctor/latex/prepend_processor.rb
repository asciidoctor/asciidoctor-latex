require 'asciidoctor'
require 'asciidoctor/extensions'

module Asciidoctor::LaTeX
  # Prepend lines to a document
  class ClickStyleInsert < Asciidoctor::Extensions::Preprocessor

    def putline line
      @@line_array += [line, ""]
    end

    def process document, reader

      warn "Entering ClickStyleInsert".magenta

      @@line_array = []

      return reader if reader.eof?

      putline '++++'
      putline '<style>'
      putline '.click .title { color: blue; }'
      putline '</style>'
      putline '++++'

      reader.unshift_lines @@line_array
      reader
    end

  end

  class MacroInsert < Asciidoctor::Extensions::Preprocessor

    def putline line
      @@line_array += [line, ""]
    end

    def process document, reader

      file_contents = IO.read('macros.tex')
      if file_contents
        warn "In FileInsert, file_contents: #{file_contents.length} chars read".yellow if $VERBOSE
      else
        warn "In FileInsert, file_contents: NIL".yellow if $VERBOSE
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

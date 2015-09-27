require 'asciidoctor'
require 'asciidoctor/extensions'


module Asciidoctor::LaTeX
  class MacroPreprocessor < Asciidoctor::Extensions::Preprocessor


    def process document, reader
      regex = /{{(.*?)}}/
      return reader if reader.eof?
      replacement_lines = reader.read_lines.map do |line|
        if line.include? '{{'
          scan = line.scan regex
          scan.each do |match|
            target = match[0]
            puts "target: #{target}".red
            line = line.gsub("{{#{target}}}", "gloss::[#{target}]")
          end
        end
        line
      end
      reader.unshift_lines replacement_lines
      reader
    end

  end
end

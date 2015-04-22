
require 'asciidoctor'
require 'asciidoctor/extensions'


class PreambleProcessor < Asciidoctor::Extensions::IncludeProcessor

  def process doc, reader, target, attributes
    content = []
    content << "He took his vorpal sword in hand,"
    content << "Longtime the manxome foe he sought"
    reader.push_include content, target, target, 1, attributes
    # reader.push_include content
    reader
  end
end



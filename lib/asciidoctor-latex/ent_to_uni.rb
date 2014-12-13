require 'asciidoctor'
require 'asciidoctor/extensions'
require 'htmlentities'

# Map HTML entties to their unicode equivalents
# before running LaTeX
class EntToUni < Asciidoctor::Extensions::Postprocessor

  def process document, output
    decoder = HTMLEntities.new
    output = decoder.decode output
  end

end

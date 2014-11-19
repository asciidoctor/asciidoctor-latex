
require 'asciidoctor'
require 'asciidoctor/extensions'

include Asciidoctor
include Asciidoctor::Extensions

require 'htmlentities'

# Map HTML entties to their unicode equivalents
# before running LaTeX
class EntToUni < Extensions::Postprocessor

  def process document, output
    decoder = HTMLEntities.new  
    output = decoder.decode output
  end
  
end
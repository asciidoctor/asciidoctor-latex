
require 'asciidoctor'
require 'asciidoctor/extensions'

include Asciidoctor
include Asciidoctor::Extensions

require_relative 'core_ext/colored_string'


# Prepend lines to a document
class PrependProcessor < Extensions::Preprocessor

  def putline line
    @@line_array += [line, ""]
  end

  def process document, reader

    @@line_array = []

    return reader if reader.eof?

    putline "++++"
    putline "<style>"
    putline ".click .title { color: blue; }"
    putline ".click .title { color: blue; }"
    putline "</style>"
    putline '<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>'
    # putline "<script src='js/jquery.js'></script>"

    putline "<script>"
    putline "$(document).ready(function(){ "
    putline "$('.openblock.click').click( function()  { $(this).find('.content').slideToggle('200') }  )"
    putline "$('.openblock.click').find('.content').hide()"
    putline  "  });"
    putline "</script>"

    putline "<script>"
    putline "$(document).ready(function(){ "
    putline "$('.listingblock.click').click( function()  { $(this).find('.content').slideToggle('200') }  )"
    putline "$('.listingblock.click').find('.content').hide()"
    putline  "  });"
    putline "</script>"

    putline "++++"

    reader.unshift_lines @@line_array
    reader
  end

end

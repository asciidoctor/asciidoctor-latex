require 'asciidoctor'

require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include ::Asciidoctor


# The following docinfo processor permits the converter to
# read an additional style file (extras.css in the data directory).
# The docinfo extension is registered in the converter.rb:
#
#   Asciidoctor::Extensions.register do
#     docinfo_processor CSSDocinfoProcessor
#     ..
#   end
#

class CSSDocinfoProcessor < Asciidoctor::Extensions::DocinfoProcessor

  use_dsl
  at_location :header


  def process doc
    extdir = File.expand_path("../../../../data", __FILE__)
    stylesheet_name = 'extras.css'
    if doc.attr? 'linkcss'
      stylesheet_href = handle_stylesheet doc, extdir, stylesheet_name
      %(<link rel="stylesheet" href="#{stylesheet_href}">)
    else
      content = doc.read_asset %(#{extdir}/#{stylesheet_name})
      ['<style>', content.chomp, '</style>'] * "\n"
    end
  end

  def handle_stylesheet doc, extdir, stylesheet_name
    outdir = (doc.attr? 'outdir') ? (doc.attr 'outdir') : (doc.attr 'docdir')
    stylesoutdir = doc.normalize_system_path((doc.attr 'stylesdir'), outdir, (doc.safe >= SafeMode::SAFE ? outdir : nil))
    if stylesoutdir != extdir && doc.safe < SafeMode::SECURE && (doc.attr? 'copycss')
      destination = doc.normalize_system_path stylesheet_name, stylesoutdir, (doc.safe >= SafeMode::SAFE ? outdir : nil)
      content = doc.read_asset %(#{extdir}/#{stylesheet_name})
      ::File.open(destination, 'w') {|f|
        f.write content
      }
      destination
    else
      %(./#{stylesheet_name})
    end
  end
end

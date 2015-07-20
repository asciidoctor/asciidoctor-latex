require 'asciidoctor'

require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include ::Asciidoctor

class CSSDocinfoProcessor < Asciidoctor::Extensions::DocinfoProcessor

  use_dsl
  at_location :header

  STYLESHEETS_DATA_PATH = ::File.join DATA_PATH, 'stylesheets'

  def extra_stylesheet_name
    'extras.css'
  end

  # Public: Read the contents of the default Asciidoctor stylesheet
  #
  # returns the [String] Asciidoctor stylesheet data
  def extra_stylesheet_data
    @extra_stylesheet_data ||= ::IO.read(::File.join(STYLESHEETS_DATA_PATH, extra_stylesheet_name)).chomp
  end

  def embed_extra_stylesheet
    %(<style>
#extra_stylesheet_data}
</style>)
  end

  def write_extra_stylesheet target_dir
    ::File.open(::File.join(target_dir, extra_stylesheet_name), 'w') {|f| f.write extra_stylesheet_data }
  end

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


require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/latex/core_ext/colored_string'

# Implements constructs like chem::[2H2O + O2 -> 2H2O]
# Maps this to \( \ce{2H2O + O2 -> 2H2O} \)
#
module Asciidoctor::LaTeX

  class ChemInlineMacro <  Asciidoctor::Extensions::InlineMacroProcessor
    use_dsl
    named :chem
    def process parent, target, attributes
      # text = attributes.values * ', ' # iky!
      array = attributes.values
      %(\\(\\ce{ #{array[0]} }\\))
    end
  end

  class GlossInlineMacro <  Asciidoctor::Extensions::InlineMacroProcessor
    use_dsl
    named :gloss
    def process parent, target, attributes
      array = attributes.values
      "<span class='glossary_term'>#{array[0]}</span>"
    end
  end

end

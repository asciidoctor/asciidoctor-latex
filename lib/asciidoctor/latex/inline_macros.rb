
require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/latex/core_ext/colored_string'

module Asciidoctor::LaTeX

  class ChemInlineMacro <  Asciidoctor::Extensions::InlineMacroProcessor
    use_dsl
    named :chem
    def process parent, target, attributes
      text = attributes.values * ', ' # iky!
      %(\\(\\ce{ #{text} }\\))
    end
  end

end

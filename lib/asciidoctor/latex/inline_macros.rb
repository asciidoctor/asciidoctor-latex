
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

  # MODEL: <a href=#gloss_entry_cammin class=glossterm id=glossterm_cammin >cammin</a>
  class GlossInlineMacro <  Asciidoctor::Extensions::InlineMacroProcessor
    use_dsl
    named :glossterm

    def glossterm(term)
      identifier = term.gsub(' ', '_').gsub(/\W/, '')
      id = 'glossterm_' + identifier
      css_class = 'glossterm'
      href = '#glossentry_' + identifier
      "<a href=#{href} class=#{css_class} id=#{id} >#{term}</a>"
    end

    def process parent, target, attributes
      term = attributes.values[0]
      glossterm(term)
    end
  end

  class IndexTermInlineMacro <  Asciidoctor::Extensions::InlineMacroProcessor
    use_dsl
    named :index_term
    def process parent, target, attributes
      array = attributes.values
      css = array.pop
      index = array.pop
      reference_array = array.pop.split(',')
      if reference_array.count == 1
        reference = reference_array.pop
      else
        reference = ''
      end
      reference ||= ''
      if css == 'invisible'
        "<span class='invisible' id='index_term_#{index}'>#{reference}</span>"
      else
        "<span class='index_term' id='index_term_#{index}'>#{reference}</span>"
      end
    end
  end

end

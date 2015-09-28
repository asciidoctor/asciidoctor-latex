
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
      term = attributes.values[0]
      id = term.gsub(' ', '_').gsub(/\W/, '')
      "<span class='glossary_term' id=gloss_#{id} >#{term}</span>"
    end
  end

=begin
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
      ref_id = "gloss_#{reference.gsub(' ', '_').gsub(/\W/, '')}"
      if css == 'invisible'
        "<span class='invisible' id=#{ref_id} >#{reference}</span>"
      else
        "<span class='index_term' id=#{ref_id} >#{reference}</span>"
      end
    end
  end
=end

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



require 'asciidoctor'
require 'asciidoctor/extensions'


module Asciidoctor::LaTeX
  # Modify the default mathJax script to run mhchem instead
  # of auto numbering of equations.  Autonumbering is taken care of
  # by [env.equation], [env.equationalign]
  #
  # See http://www.noteshare.io/section/the-chem-environment
  #
  # This is a hack. #FIXME!
  class Chem < Asciidoctor::Extensions::Postprocessor

    def process(document, output)
      output.gsub(TEX_SNIPPET, CHEM_SNIPPET)
    end

  end


  TEX_SNIPPET = 'TeX: { equationNumbers: { autoNumber: "none" } }'
  # In the standard MathJax script


  CHEM_SNIPPET = 'TeX: { extensions: ["mhchem.js"] }'
  # What we want in the MathJax script


end

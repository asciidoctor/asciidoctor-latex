

require 'asciidoctor'
require 'asciidoctor/extensions'

module Asciidoctor::LaTeX
  # Map @@DOLLAR: to $
  class Chem < Asciidoctor::Extensions::Postprocessor

    def process document, output
      warn "Chem _process".magenta if $VERBOSE
      output = output.gsub($tex_snippet, $chem_snippet)
    end

  end
end

$tex_snippet = 'TeX: { equationNumbers: { autoNumber: "none" } }'
$chem_snippet = 'TeX: { extensions: ["mhchem.js"] }'


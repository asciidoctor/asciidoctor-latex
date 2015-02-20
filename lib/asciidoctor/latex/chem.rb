

require 'asciidoctor'
require 'asciidoctor/extensions'

# Modify the default mathJax script to run mhchem instead
# of autonumbuering of equations -- which is taken care of
# by [env.equation], [env.equationalign]
#
# See http://www.noteshare.io/section/the-chem-environment
#
module Asciidoctor::LaTeX
  # Map @@DOLLAR: to $
  class Chem < Asciidoctor::Extensions::Postprocessor

    def process document, output
      output = output.gsub($tex_snippet, $chem_snippet)
    end

  end
end

$tex_snippet = 'TeX: { equationNumbers: { autoNumber: "none" } }'
$chem_snippet = 'TeX: { extensions: ["mhchem.js"] }'

module Asciidoctor
  module LaTeX
    DATA_DIR = File.expand_path '../../data', __dir__
  end
end

require 'asciidoctor/latex/version'
require 'asciidoctor/latex/converter'

module Asciidoctor
  module LaTeX
    # Old -- to remove:
    #DATA_DIR = File.expand_path '../../data', __dir__

    # -- per @Mogztter's suggestion, needed for compatibility with Opal:
    DATA_DIR = (::File.dirname ::File.dirname ::File.dirname ::File.expand_path __FILE__) + '/data'
  end
end

require 'asciidoctor/latex/version'
require 'asciidoctor/latex/converter'

# This is a test file for the asciidoctor-latex toolchain.
# Run it on the sibling file ../samples/env.doc using
# 
#  $ ruby env_test.rb --html
#
#  or
#
#  $ ruby env_test.rb --tex
#
# The source text is 'samples/env.adoc'
#
# The toolchain thus far consists of the following five components.
#
#   -- a preprocessor so that matheamticians can use $ ... $
#      for inline matheamatical text.
#
#   -- a postprocessor to map HMTL entities to their unicode equivalents
#
#   -- a block processor to recognize and handle 'environment' blocks
#      of the form
#
#      [env.theorem]
#      --
#      There are infinitely many prime nunbers.
#      --
#
#      Such blocks are handled one way by the HTML backend, another
#      way tby the tex backend.  More details below.
#
#   -- A file 'block_environment.html.haml' file to augment the existing
#      templates, i.e., to  handle the environment block whent he backend
#      is HTML.
#
#   -- A backkend for latex.  See asciidoctor-latex.
#
#   NOTE: I think that 'block_environment.html.haml' should be added to the standard
#   set of templates.  As it is, when I refer to a custom template directory,
#   I get almost plain vanilla output ... only the new template is operative.
#
#   NOTE ALSO: The block_environment template is a very slight variation on the 
#   open block template: diffrent name, italicizd body, that's it.


AD = "/Users/carlson/Dropbox/prog/git/asciidoctor/bin/asciidoctor"                             # Asciidoctor
PRE = "/Users/carlson/Dropbox/prog/git/asciidoctor-extensions-lab/lib/tex-preprocessor.rb"     # Preprocessor 
POST = "/Users/carlson/Dropbox/prog/git/asciidoctor-extensions-lab/lib/ent2uni.rb "            # Postprocessor
LCO = "/Users/carlson/Dropbox/prog/git/asciidoctor-latex/lib/asciidoctor-latex/converter.rb "  # Latex converter

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'htmlentities'
require 'tilt'

include Asciidoctor
include Asciidoctor::Extensions


# Map $ ... $ to latexmath:[ ... ] before
# running Asciidoctor
class TeXPreprocessor < Extensions::Preprocessor

  # Map $...$ to stem:[...]
  TEX_DOLLAR_RX = /(^|\s|\()\$(.*?)\$($|\s|\)|,|\.)/
  TEX_DOLLAR_SUB = '\1latexmath:[\2]\3'


  def process document, reader
    return reader if reader.eof?
    replacement_lines = reader.read_lines.map do |line|
      (line.include? '$') ? (line.gsub TEX_DOLLAR_RX, TEX_DOLLAR_SUB) : line
    end
    reader.unshift_lines replacement_lines
    reader
  end

end

# Detect constructs of form
#
#    [env.theorem]
#    --
#    Ho ho, this is test: $a^2 = 1$
#    --
# 
# The construct a block of type environment
# with title = environment name capitalized.
# In this case the title is "Theorem", but 
# it could be anything. Consider: [env.joke]
#
# In addition create and/or update a counter
# tied to the environment name and use it
# to augment the title, so that we have
# "Theorem 7", "Joke 43", etc.
#
# If the backend is HTML, the effect is as if
# the block had been
#
#    .Theorem {counter:theorem}
#    --
#    Ho ho, ...
#    --
# 
# excpet that the body ("Ho ho, ...") is italicized
# in accordance with LaTeX convention.  All of
# this is handled by the file
#
#   block_environment.html.haml
#
# If the backend s LaTeX, then the text
#
#    \begin{theorem}
#    Ho ho, ...
#    \end{theorem}
#
# is emitted instead.
#
#
class EnvironmentBlock < Extensions::BlockProcessor

  use_dsl

  named :env
  on_context :open
  # parse_context_as :complex
  # ^^^ The above line gave me an error. I'm not sure what do to with it.

  # Hash to count the number of times each environment is encountered
  # Global variables again. Is there a better way?
  $counter = {}

  def process parent, reader, attrs
    puts "found: EnvironmentBlock"
    env_name = attrs["role"]
    if $counter[env_name] == nil
      $counter[env_name] = 1
    else
      $counter[env_name] += 1
    end
    attrs["title"] = env_name.capitalize + " " + $counter[env_name].to_s
    create_block parent, :environment, reader.lines, attrs
  end
  
end

# Map HTML entties to their unicode equivalents
# before running LaTeX
class EntToUni < Extensions::Postprocessor

  def process document, output
    decoder = HTMLEntities.new  
    output = decoder.decode output
  end
  
end


Extensions.register do
  preprocessor TeXPreprocessor
  postprocessor EntToUni
end


Extensions.register :latex do
  block EnvironmentBlock
end

if ARGV.count == 0
  puts "Please say 'ruby env.rb --html' or 'ruby env.rb --tex"
  exit
end


if ARGV[0] == "--html"
  Asciidoctor.render_file '../samples/env.adoc', :template_dir => 'templates'
  puts "Output is in 'samples/env.html'"
else  
  cmd = "#{AD} -r #{PRE} -r #{POST} -r #{LCO} -b latex"
  cmd = cmd + " ../samples/env.adoc"
  system(cmd)
  puts "Output is in 'samples/env.tex'"
end



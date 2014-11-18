# Test doc: work/click.adoc


# ClickBlock is a first draft for 

# Note to self: when done with this, eliminate 
# the puts lines with DEVELOPMENT
# or toggle them with $VERBOSE

require 'asciidoctor'
require 'asciidoctor/extensions'

include Asciidoctor
include Asciidoctor::Extensions
 
class ClickBlock < Extensions::BlockProcessor
  
  require_relative 'colored_text'
  
  use_dsl
  # ^^^ don't know what this is.  Could you explain?

  named :click
  on_context :open
  # parse_context_as :complex
  # ^^^ The above line gave me an error.  I'm not sure what do to with it.
  
  # Hash to count the number of times each environment is encountered
  # Global variables again.  Is there a better way?
  $counter = {}

  def process parent, reader, attrs
    
    warn "begin ClickBlock".blue if $VERBOSE
    click_name = attrs["role"]
    
    if $counter[click_name] == nil
      $counter[click_name] = 1
    else
      $counter[click_name] += 1
    end
      
    attrs["title"] = click_name.capitalize + " " + $counter[click_name].to_s 
    
    warn "click_name: #{click_name}".cyan if $VERBOSE 
    warn "end Clicklock\n".blue if $VERBOSE  
      
    create_block parent, :click, reader.lines, attrs
  end
  
end


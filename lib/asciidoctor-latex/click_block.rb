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
    
    # Ensure that the role is defined
         if attrs['role'] == nil
           role = '__item'
         else
           role = attrs['role']
         end

         # Should the block be numbered?
         numbered = false
         if attrs['options'] and attrs['options'].include? 'numbered'
             numbered = true
         end
         
         puts "logging ... ".cyan
         puts "attrs['options'] = #{attrs['options']}".cyan



         # If the block is numbered, update the counter
         if numbered
           click_name = 'click-'+role
           if $counter[click_name] == nil
             $counter[click_name] = 1
           else
             $counter[click_name] += 1
           end
         end

         # Set pseudo role
         if role == 'code'
           pseudo_role = 'listing'
         elsif role == '__item'
           pseudo_role = 'item'
         else
           pseudo_role = role
         end

         # Set title
         if attrs['title']
           title = attrs['title']
         else
           title = ''
         end

         if numbered
           if title != ''
             title = pseudo_role.capitalize + " #{$counter[click_name]}. #{title}"
           else
             title = pseudo_role.capitalize + " #{$counter[click_name]}"
           end
         end

         if !numbered and title == ''
           if role == '__item'
             title = 'Item'
           else
             title = pseudo_role.capitalize
           end
         end
  
      
         attrs['title'] = title
      
      
    attrs['role'] = 'click'
    
    warn "click_name: #{click_name}".cyan if $VERBOSE 
    warn "end Clicklock\n".blue if $VERBOSE  
      
    create_block parent, :click, reader.lines, attrs
  end
  
end



class String

  def eos
    return ''  if self == ''
    n = self.length - 1
    return self[n]
  end

  def whack
    return '' if self == ''
    n = self.length - 1
    return self[0...n]
  end

end

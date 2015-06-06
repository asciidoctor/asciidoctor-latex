# Test doc: work/click.adoc


# ClickBlock implements the construct
#
#  [click.answer]
#  --
#  73
#  --
#
# See http://epsilon.my.noteshare.io/lessons/click-blocks-jc
#
# Documents containing click-blocks must be rendered with
#
# asciidoctor-latex -b html -a click_extras=include
#
require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/latex/core_ext/colored_string'


module Asciidoctor::LaTeX
  class ClickBlock < Asciidoctor::Extensions::BlockProcessor

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

      original_title = attrs["role"]

      # Ensure that role is defined
       original_role = attrs['role']
       if attrs['role'] == nil
         role = 'item'
       else
         role = attrs['role']
       end

       # Use the value of the role to determine
       # whether this is a numbered block
       numbered = false
       if attrs['options'] and attrs['options'].include? 'number'
         numbered = true
       end


       # If the block is numbered, update the counter
       if numbered
         env_name = role     ##############  'click-'+role
         if $counter[env_name] == nil
           $counter[env_name] = 1
         else
           $counter[env_name] += 1
         end
       end


       # Set title
       if role == 'code'
         title = 'Listing'
       else
         title = role.capitalize
       end
       if numbered
         title = title + ' ' + $counter[env_name].to_s
       end
       if attrs['title']
         if numbered
           title = title + '. ' + attrs['title'].capitalize
         else
           title = title + ': ' + attrs['title'].capitalize
         end
       end

      if original_role == nil
        title = original_title
      end

       if role != 'equation'
         attrs['title']  = title
       else
         if numbered
           attrs['equation_number'] = $counter[env_name].to_s
         end
       end


      attrs['title'] = title


      if attrs['role'] == 'code'
        role = 'listing'
      else
        role  = 'click'
      end
      attrs['role'] = 'click'

      attrs['original_title'] = original_title

      if role == 'listing'
        block = create_block parent, :listing, reader.lines, attrs
      else
        block = create_block parent, :click, reader.lines, attrs
      end

    block

    end

  end
end


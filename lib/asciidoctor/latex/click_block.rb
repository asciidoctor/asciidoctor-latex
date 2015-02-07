# Test doc: work/click.adoc


# ClickBlock is a first draft for

# Note to self: when done with this, eliminate
# the puts lines with DEVELOPMENT
# or toggle them with $VERBOSE

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

      warn "begin ClickBlock".blue if $VERBOSE
      click_name = attrs["role"]

      # Ensure that role is defined
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


      warn "click_name: #{click_name}".cyan if $VERBOSE
      warn "end Clicklock\n".blue if $VERBOSE

      warn "role = #{role}".red if $VERBOSE
      if role == 'listing'
        warn "creating listing block".red if $VERBOSE
        create_block parent, :listing, reader.lines, attrs
      else
        warn "creating click block".red if $VERBOSE
        create_block parent, :click, reader.lines, attrs
      end

    end

  end
end



require 'asciidoctor/extensions'

module Asciidoctor::LaTeX

  class ClickInsertion < Asciidoctor::Extensions::Postprocessor

    def process document, output
      warn "Entering ClickInsertion, process".magenta if $VERBOSE
      output = output.gsub('</head>', $click_insertion)
    end

  end

  $click_insertion = <<EOF

<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>

<script>

  $(document).ready(function(){
    $('.openblock.click').click( function()  { $(this).find('.content').slideToggle('200') }  )
    $('.openblock.click').find('.content').hide()
  });

</script>

<script>

  $(document).ready(function(){
    $('.listingblock.click').click( function()  { $(this).find('.content').slideToggle('200') }  )
    $('.listingblock.click').find('.content').hide()
  });

</script>
</head>

EOF

end


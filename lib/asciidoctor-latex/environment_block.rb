# Test doc: samples/env.adoc


# EnvironmentBlock is a first draft for a better
# way of handing a construct in Asciidoc that
# will map to LaTeX environments.  See
# issue #1 in asciidoctor/asciidoctor-latex.
#
# The code below is based on @mojavelinux's
# outline. The EnvironmentBlock is called
# into action (please ... give me a more
# precise phrase here!) when text
# of the form [env.foo] is encountered.
# This is the signal to create a block
# of type environment. (Is this correct?)
# and environment-type "foo"
#
# In the act of creating an environment
# block, information extracted from
# [env.foo] is used to title the block
# as "Foo n", where n is a counter for
# environments of type "foo".  The
# counter is created in a hash the first
# time an environment of that kind
# is encountered.  We set
#
#    counter["foo"] = 1
#
# Subsequent encounters cause the
# counter to be incremented.
#
# Later, when the backend process the AST,
# the information bundled by the
# EnvironmentBlock is used as is
# appropriate. In the case of conversion
# to LaTeX, the content of the block
# simply enclosed in delimiters as
# follows:
#
# \begin{foo} CONTENT \end{foo}
#
# Additionally, label information
# for cross-referencing is added at
# this stage.
#
# If, on the other hand, the backend
# is HTML, then the title (with numbering)
# that is extracted from [env.foo] is used
# to title the block.  Additional styling
# is added so as to conform to LaTeX
# conventions: the body of the block is
# italicized.


require 'asciidoctor'
require 'asciidoctor/extensions'
include Asciidoctor
include Asciidoctor::Extensions

class EnvironmentBlock < Extensions::BlockProcessor

  require_relative 'colored_text'
  # require

  use_dsl

  named :env
  on_context :open
  # parse_context_as :complex
  # ^^^ The above line gave me an error.  I'm not sure what do to with it.

  # Hash to count the number of times each environment is encountered
  # Global variables again.  Is there a better way?
  $counter = {}
  $ref2counter = {}

  def process parent, reader, attrs


    # Ensure that role is defined
     if attrs['role'] == nil
       role = 'item'
     else
       role = attrs['role']
     end

     # Use the value of the role to determine
     # whether this is a numbered block
     numbered = true
     if attrs['options'] and attrs['options'].include? 'no-number'
       numbered = false
     end


     # If the block is numbered, update the counter
     if numbered
       env_name = role   ##################'env-'+role
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
       title = title + '. ' + attrs['title'].capitalize
     end

     if role != 'equation'
       attrs['title']  = title
     else
       if numbered
         attrs['equation_number'] = $counter[env_name].to_s
       end
     end

     if numbered and attrs['id']
       $ref2counter[attrs['id']] = $counter[env_name].to_s
       puts "$ref2counter: #{attrs['id']} => #{$counter[env_name].to_s}".yellow
     end


    warn "env_name: #{env_name}".cyan if $VERBOSE
    warn "end EnvironmentBlock\n".blue if $VERBOSE

    if attrs['role'] == 'code'
      create_block parent, :listing, reader.lines, attrs
    else
      create_block parent, :environment, reader.lines, attrs
    end

  end

end

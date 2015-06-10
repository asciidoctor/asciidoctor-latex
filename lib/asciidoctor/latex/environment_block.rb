# Test doc: samples/env.adoc

# EnvironmentBlock implements constructs of the form
#
# [env.TYPE]
# --
# foo, bar, etc.
# --
#
# e.g.,
#
# [env.theorem]
# --
# $2 + 2  = 4$. Cool!
# --
#
# TYPE can be anything, but certain values, e.g.,
# 'equation', 'equationalign', 'code' receive
# special handling.
#
# See  http://www.noteshare.io/section/environments
#
#
#


# OLD NOTES
#
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
require 'asciidoctor/latex/core_ext/colored_string'


module Asciidoctor::LaTeX


  class EnvironmentBlock < Asciidoctor::Extensions::BlockProcessor

    use_dsl

    named :env
    on_context :open
    # parse_context_as :complex
    # ^^^ The above line gave me an error.  I'm not sure what do to with it.

    def process parent, reader, attrs

      original_title = attrs['title']
      attrs['original_title'] = attrs['title']

      # Ensure that role is defined
      if attrs['role'] == nil
        role = 'item'
      else
        role = attrs['role']
      end

      # fixme: this should not be necessary
      if attrs['role'] =~ /\\/
        attrs['role'] = attrs['role'].gsub(/\\/, '')
      end

      # Determine whether the block is numbered
      # Use the option set if present (numbered, no+_number) otherwise
      # use a default value, e.g. 'box' is not numbered, the others are numbered
      if !(attrs['options'] =~ /no_number|numbered/)
        if %w(box equation equationalign).include? role
          attrs['options'] = 'no_number'
        else
          attrs['options'] = 'numbered'
        end
      end
      if attrs['id']
        attrs['options'] = 'numbered'
      end


      # Adjust title according to environment name
      env_name = role # roles.first # FIXME: roles.first is probably best
      if %w(equation equationalign chem).include? role
        attrs['title'] = env_name
      elsif role == 'code'
        if attrs['id'] or attrs['title']
          attrs['title'] = 'Listing'
        else
          attrs['title'] = ''
          attrs['options'] = 'no_number'
        end
      elsif role == 'jsxgraph'
        attrs['title'] = 'JSXGraph'
      elsif role == 'box'
        attrs['title'] = ''
      else
        attrs['title'] = env_name.capitalize
      end
      env_title = attrs['title']


      # Creat the block
      if attrs['role'] == 'code'
        warn "for rode = code, attrs = #{attrs}".cyan
        block = create_block parent, :listing, reader.lines, attrs
      else
        block = create_block parent, :environment, reader.lines, attrs
      end

      if attrs['options'] =~ /numbered/
        # THE NUMBERED OPTION
        # Use same prefix for cross referencing for the
        # equation_align environment as for the equation
        # environment so as not to have separate numbering
        # sequences
        if env_name == 'equationalign'
          env_ref_prefix = 'equation'
        else
          env_ref_prefix = env_name
        end
        # Define caption_num so that we can make references
        # that display as "(17)", for example
        # This is where we can set the caption number by hand
        # once I figure out how to do so.
        caption_num = parent.document.counter_increment("#{env_ref_prefix}-number", block)
        attrs['caption-num'] = caption_num
        caption = "#{caption_num}"
        # Set the title, e.g., "Theorem 3: Pythagoras" or just "Theorem 3"
        # depending on whether the user sets a title, .e.g, ".Pythagoras"
        # in the line preceding "[env.theorem]"
        if original_title
          attrs['title'] = "#{env_title} #{caption_num}: #{original_title}"
        else
          attrs['title'] = "#{env_title} #{caption_num}."
        end
      else
        # THE NON-NUMBERED OPTION
        # Set the title, e.g., "Pythagoras" or just "Theorem"
        # depending on whether the user sets a title, .e.g, ".Pythgoras"
        # in the line preceding "[env.theorem]"
        # FIXME: this code is a tad spaghetti-like
        if original_title
          if  %w(box).include? role
            attrs['title'] = "#{original_title}"
          else
            attrs['title'] = "#{env_title}: #{original_title}"
          end
        else
          attrs['title'] = "#{env_title}"
        end
      end

      if attrs['role'] == 'code'
        caption = nil
      end

      block.assign_caption caption
      if %w(equation equationalign chem).include? role
        block.title = "#{caption_num}"
      else
        block.title = attrs['title']
      end
      block

    end

  end
end

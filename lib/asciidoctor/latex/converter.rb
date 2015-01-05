
#
# File: latex-converter.rb
# Author: J. Carlson (jxxcarlson@gmail.com)
# Date: 9/26/2014
#
# This is a first step towards writing a LaTeX backend
# for Asciidoctor. It is based on the
# Dan Allen's demo-converter.rb.  The "convert" method
# is unchanged, the methods "document node" and "section node"
# have been redefined, and several new methods have been added.
#
# The main work will be in identifying asciidoc elements
# that need to be transformed and adding a method for
# each such element.  As noted below, the "warn" clause
# in the "convert" method is a useful tool for this task.
#
# Usage:
#
#   $ asciidoctor -r ./latex-converter.rb -b latex test/sample1.adoc
#
# Comments
#
#   1.  The "warn" clause in the converter code is quite useful.
#       For example, you will discover in running the converter on
#       "test/sample-1.adoc" that you have not implemented code for
#       the "olist" node. Thus you can work through ever more complex
#       examples to discover what you need to do to increase the coverage
#       of the converter. Hackish and ad hoc, but a process nonetheless.
#
#   2.  The converter simply passes on what it does not understand, e.g.,
#       LaTeX, This is good. However, we will have to map constructs
#       like"+\( a^2 = b^2 \)+" to $ a^2 + b^2 $, etc.
#       This can be done at the preprocessor level.
#
#   3.  In view of the preceding, we may need to chain a frontend
#       (preprocessor) to the backend. In any case, the main work
#       is in transforming Asciidoc elements to TeX elements.
#       Other than the asciidoc ->  tex mapping, the tex-converter
#       does not need to understand tex.
#
#   4.  Included in this repo are the files "test/sample1.adoc", "test/sample2.adoc",
#       and "test/elliptic.adoc" which can be used to test the code
#
#   5.  Beginning with version 0.0.2 we use a new dispatch mechanism
#       which should permit one to better manage growth of the code
#       as the coverage of the converter increases. Briefly, the
#       main convert method, whose duty is to process nodes, looks
#       at node.node_name, then makes the method call node.tex_process
#       if the node_name is registered in NODE_TYPES. The method
#       tex_process is defined by extending the various classes to
#       which the node might belong, e.g., Asciidoctor::Block,
#       Asciidoctor::Inline, etc.  See the file "node_processor.rb",
#       where these extensions are housed for the time being.
#
#       If node.node_name is not found in NODE_TYPES, then
#       a warning message is issued.  We can use it as a clue
#       to find what to do to handle this node.  All the code
#       in "node_processors.rb" to date was written using this
#       hackish process.
#
#
#  CURRENT STATUS
#
#  The following constructs are processed
#
#  * sections to a depth of five, e.g., == foo, === foobar, etc.
#  * ordered and unordered lists, though nestings is untested and
#    likely does not work.
#  * *bold* and _italic_
#  * hyperlinks like http://foo.com[Nerdy Stuff]
#

require 'asciidoctor'
require 'asciidoctor/converter/html5'
require 'asciidoctor/latex/core_ext/colored_string'
require 'asciidoctor/latex/click_block'
require 'asciidoctor/latex/ent_to_uni'
require 'asciidoctor/latex/environment_block'
require 'asciidoctor/latex/node_processors'
require 'asciidoctor/latex/prepend_processor'
require 'asciidoctor/latex/tex_block'
require 'asciidoctor/latex/tex_preprocessor'
# require 'asciidoctor/latex/preamble_processor'


# code for Html5ConverterExtension & its insertion
# template by @mojavelinux
module Asciidoctor::LaTeX
  module Html5ConverterExtensions

    def info node

      attrs =  node.attributes

      warn "\n    node: #{node.node_name}".cyan
      warn "   attrs: #{attrs}".cyan
      warn "   title: #{attrs['title']}".cyan
      warn "    role: #{attrs['role']}".cyan
      warn "   level: #{attrs['level']}".cyan
      warn " options: #{attrs['options']}".cyan
      warn " type   : #{attrs['type']}".cyan
      warn " caption: #{node.caption}".red
      warn "      id: #{attrs['id']}".cyan
      warn " content: #{node.content}".blue

    end

    def environment node

      info node if $VERBOSE
      options = node.attributes['options']
      attrs = node.attributes

      if attrs['role'] == 'equation'
        attrs['title'] = nil
        warn "hc: ".cyan + "title = #{attrs['title']}".red + "options = #{options}, caption = #{node.caption}".yellow
        number_part = '<td style="text-align:right">' + "(#{node.caption}) </td>"
        number_part = ["+++ #{number_part} +++"]
        equation_part = ['+++<td>+++'] + ['\\['] + node.lines + ['\\]'] + ['+++</td>+++']
        table_style='style="width:100%; border-collapse:collapse;border:0"'
        # row_style='style="border-collapse: collapse"'
        row_style='class="zero" style="border-collapse: collapse; border:0; font-size: 10pt; "'
        if options['numbered']
          node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + number_part + ['+++</tr></table>+++']
        else
          node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + ['+++</tr></table>+++']
        end
        # node.title = "(#{node.attributes['equation_number']})"
      else
        warn "hc: ".blue + "title = #{attrs['title']}".red + ", options = #{options}, caption = #{node.caption}".yellow
        node.lines = ["+++<div style='line-height:1.5em;font-size:1.05em;font-style:oblique;margin-bottom:1.5em'>+++"] + node.lines + ["+++</div>+++"]
      end

      node.attributes['roles'] = (node.roles + ['environment']) * ' '
      self.open node
    end

    def click node
      info node if $VERBOSE
      node.lines = ["+++<div style='line-height:1.5em;font-size:1.05em;font-style:oblique;margin-bottom:1.5em'>+++"] + node.lines + ["+++</div>+++"]
      node.attributes['roles'] = (node.roles + ['click']) * ' '
      self.open node
    end

    def inline_anchor node
      case node.type.to_s
      when 'xref'
        refid = node.attributes['refid']
        if refid and refid[0] == '_'
          output = "<a href=\##{refid}>#{refid.gsub('_',' ')}</a>"
        elsif $ref2counter[refid]
          output = "<a href=\##{refid} style='text-decoration:none'>(#{$ref2counter[refid]})</a>"
        end
      when 'link'
        output = "<a href=#{node.target}>#{node.text}</a>"
      else
        output = "FOOBAR"
      end
      output
    end

  end


  class Converter
    include Asciidoctor::Converter

    register_for 'latex'


    Asciidoctor::Extensions.register do
      preprocessor TeXPreprocessor
      block EnvironmentBlock
      block ClickBlock
      preprocessor PrependProcessor if document.basebackend? 'html'
      postprocessor EntToUni if document.basebackend? 'tex'
    end


    Asciidoctor::Extensions.register :latex do
      # EnvironmentBlock
    end


    TOP_TYPES = %w(document section)
    LIST_TYPES = %w(olist ulist )
    INLINE_TYPES = %w(inline_anchor inline_break inline_footnote inline_quoted)
    BLOCK_TYPES = %w(admonition listing literal page_break paragraph stem pass open quote)
    OTHER_TYPES = %w(environment table)
    NODE_TYPES = TOP_TYPES + LIST_TYPES + INLINE_TYPES + BLOCK_TYPES + OTHER_TYPES

    def initialize backend, opts
      warn "initialize converter".magenta if $VERBOSE
      super
      basebackend 'tex'
      outfilesuffix '.tex'
    end

    $latex_environment_names = []
    $label_counter = 0

    def convert node, transform = nil

      if NODE_TYPES.include? node.node_name
        node.tex_process
      else
        warn %(Node to implement: #{node.node_name}, class = #{node.class}).magenta
        # This warning should not be switched off by $VERBOSE
      end

    end

  end
end


class Asciidoctor::Converter::Html5Converter
  # inject our custom code into the existing Html5Converter class (Ruby 2.0 and above)
  prepend Asciidoctor::LaTeX::Html5ConverterExtensions
end

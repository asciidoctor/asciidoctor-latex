
#
# File: latex-converter.rb
# Author: J. Carlson (jxxcarlson@gmail.com)
# First commit: 9/26/2014
# Date: 2/20/1015
#
# OVERVIEW
#
# Asciidoctor-latex does two things:
#
#   -- provides an HTML backend which adds latex-like features to asciidoctor
#      asciidoc(tor) with these additional features will be called 'asciidoctor-latex'
#
#  -- provides a converter from asciidoctor-latex to asciidoctor.  This converter
#     is 'usable' but has limited coverage of asciidoctor-latex
#
# See http://www.noteshare.io/section/asciidoctor-latex-manual-intro
# for a description (with examples) of asciidoctor-latex.
#
# INSTALLATION
#
# Run 'rake install' to install the asciidoctor-latex gem locally.
#
# USAGE (1: html)
#
# Run
#
#     'asciidoctor-latex -b html foo.adoc'
#
# to render an asciidoctor-latex document to html
#
# Some documents (those with 'click blocks', see http://www.noteshare.io/section/homework-problems)
# For these, run
#
#     'asciidoctor-latex -b html -a click_extras=include foo.adoc'
#
# In both cases the output is 'foo.html'
#
# USAGE (2: latex)
#
# Run
#
#      'asciidoctor-latex foo.adoc'
#
# to convert foo.adoc to foo.tex.  This feature
# needs a lot of work.
#
# to convert foo.tex to the latex file foo.latex
# You can put files 'macros.tex' and 'preamble.tex' to
# replace the default preamble and set of macros.
# Define your own 'newEnvironments.tex' to use yours
# as opposed to the default definitons of environments
# in tex mapping to [tex.ENVIRNOMENT] in asciidoctor-latex.
#
# TECHNICAL NOTES
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
require 'asciidoctor/latex/inline_macros'
require 'asciidoctor/latex/core_ext/colored_string'
require 'asciidoctor/latex/click_block'
require 'asciidoctor/latex/inject_html'
require 'asciidoctor/latex/ent_to_uni'
require 'asciidoctor/latex/environment_block'
require 'asciidoctor/latex/node_processors'
require 'asciidoctor/latex/prepend_processor'
require 'asciidoctor/latex/macro_insert'
require 'asciidoctor/latex/tex_block'
require 'asciidoctor/latex/tex_preprocessor'
require 'asciidoctor/latex/dollar'
require 'asciidoctor/latex/tex_postprocessor'
require 'asciidoctor/latex/chem'



# require 'asciidoctor/latex/preamble_processor'

$VERBOSE = true



module Asciidoctor::LaTeX

  # code for Html5ConverterExtension & its insertion
  # template by @mojavelinux
  module Html5ConverterExtensions


    # ENV_CSS_OBLIQUE = "+++<div class='env_oblique'>+++"
    # ENV_CSS_NOBLIQUE = "+++<div class='env_noblique'>+++"

    ENV_CSS_OBLIQUE = "+++<div style='line-height:1.5em;font-size:1.05em;font-style:oblique;margin-bottom:1.5em'>+++"
    ENV_CSS_PLAIN = "+++<div style='line-height:1.5em;font-size:1.05em;;margin-bottom:1.5em'>+++"

    DIV_END = '+++</div>+++'
    TABLE_ROW_END = '+++</tr></table>+++'

    def info node

      warn "\n   HTMLConverter, node: #{node.node_name}".red if $VERBOSE

    end

    # Dispatches a handler for the _node_ (`NODE`)
    # based on its role.
    def environment node

      attrs = node.attributes

      case attrs['role']
        when 'box'
          handle_null(node)
        when 'equation'
          handle_equation(node)
        when 'equationalign'
          handle_equation_align(node)
        when 'chem'
          handle_chem(node)
        when 'jsxgraph'
          handle_jsxgraph(node)
        else
          handle_default(node)
      end

      node.attributes['roles'] = (node.roles + ['environment']) * ' '
      self.open node
    end

    def click node
      if node.attributes['plain-option']
        node.lines = [ENV_CSS_PLAIN] + node.lines + [DIV_END]
      else
        node.lines = [ENV_CSS_OBLIQUE] + node.lines + [DIV_END]
      end
      # node.lines = [ENV_CSS] + node.lines + [DIV_END]
      node.attributes['roles'] = (node.roles + ['click']) * ' '
      self.open node
    end

    def inline_anchor node

      case node.type.to_s
      when 'xref'
        refid = node.attributes['refid']
        if refid and refid[0] == '_'
          output = "<a href=\##{refid}>#{refid.gsub('_',' ')}</a>"
        else
          refs = node.parent.document.references[:ids]
          # FIXME: the next line is HACKISH (and it crashes the app when refs[refid]) is nil)
          # FIXME: and with the fix for nil results is even more hackish
          if refs[refid]
            reftext = refs[refid].gsub('.', '')
            reftext = reftext.gsub(/:.*/,'')
            if refid =~ /\Aeq-/
              output = "<span><a href=\##{refid}>equation #{reftext}</a></span>"
            elsif refid =~ /\Aformula-/
              output = "<span><a href=\##{refid}>formula #{reftext}</a></span>"
            elsif refid =~ /\Areaction-/
              output = "<span><a href=\##{refid}>reaction #{reftext}</a></span>"
            else
              output = "<span><a href=\##{refid} style='text-decoration:none'>#{reftext}</a></span>"
            end
          else
            output = 'ERROR: refs[refid] was nil'
          end
        end
      when 'link'
        output = "<a href=#{node.target}>#{node.text}</a>"
      else
        output = 'FOOBAR'
      end
      output
    end

    def handle_equation(node)
      attrs = node.attributes
      node.title = nil
      warn "node.attributes (EQUATION): #{node.attributes}".cyan if $VERBOSE
      number_part = '<td style="text-align:right">' + "(#{node.caption}) </td>"
      number_part = ["+++ #{number_part} +++"]
      equation_part = ['+++<td style="width:100%";>+++'] + ['\\['] + node.lines + ['\\]'] + ['+++</td>+++']
      table_style='style="width:100%; border-collapse:collapse;border:0"  class="zero" '
      row_style='style="border-collapse: collapse; border:0; font-size: 12pt; "'
      if attrs['numbered-option']
        node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + number_part + [TABLE_ROW_END]
      else
        node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + [TABLE_ROW_END]
      end
    end

    def handle_equation_align(node)
      attrs = node.attributes
      warn "node.attributes (EQUATION ALIGN): #{node.attributes}".cyan if $VERBOSE
      node.title = nil
      number_part = '<td style="text-align:right">' + "(#{node.caption}) </td>"
      number_part = ["+++ #{number_part} +++"]
      equation_part = ['+++<td style="width:100%";>+++'] + ['\\[\\begin{split}'] + node.lines + ['\\end{split}\\]'] + ['+++</td>+++']
      table_style='style="width:100%; border-collapse:collapse;border:0"  class="zero" '
      row_style='style="border-collapse: collapse; border:0; font-size: 12pt; "'
      if attrs['numbered-option']
        node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + number_part + [TABLE_ROW_END]
      else
        node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + [TABLE_ROW_END]
      end
    end

    def handle_chem(node)
      node.title = nil
      number_part = '<td style="text-align:right">' + "(#{node.caption}) </td>"
      number_part = ["+++ #{number_part} +++"]
      equation_part = ['+++<td style="width:100%;">+++'] + [' \\[\\ce{' + node.lines[0] + '}\\] '] + ['+++</td>+++']
      table_style='class="zero" style="width:100%; border-collapse:collapse; border:0"'
      row_style='class="zero" style="border-collapse: collapse; border:0; font-size: 10pt; "'
      node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"]  + equation_part + number_part +['+++</tr></table>+++']
    end

    def handle_jsxgraph(node)
      attrs = node.attributes
      if attrs['box'] == nil
        attrs['box'] = 'box'
      end
      if attrs['width'] == nil
        attrs['width'] = 450
      end
      if attrs['height'] == nil
        attrs['height'] = 450
      end
      line_array = ["\n+++\n"]
      # line_array += ["<link rel='stylesheet' type='text/css'  href='jsxgraph.css' />"]

      line_array += ["<link rel='stylesheet' type='text/css'  href='http://jsxgraph.uni-bayreuth.de/distrib/jsxgraph.css' />"]
      line_array += ['<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/jsxgraph/0.99.3/jsxgraphcore.js"></script>']
      line_array += ["<script src='http://jsxgraph.uni-bayreuth.de/distrib/GeonextReader.js' type='text/javascript'></script>"]
      # line_array += ['<div id="box" class="jxgbox" style="width:500px; height:500px;"></div>']
      line_array += ["<div id='#{attrs['box']}' class='jxgbox' style='width:" + "#{attrs['width']}" + "px; height:" + "#{attrs['height']}" +"px;'></div>"]
      line_array += ['<script type="text/javascript">']

      line_array += node.lines
      line_array += ['</script>']
      line_array += ['<br/>']
      line_array += ["\n+++\n"]
      node.lines = line_array
    end

    def handle_null(node)

    end

    def handle_default(node)
        if node.attributes['plain-option']
          node.lines = [ENV_CSS_PLAIN] + node.lines + [DIV_END]
        else
          node.lines = [ENV_CSS_OBLIQUE] + node.lines + [DIV_END]
        end
    end

  end


  class Converter
    include Asciidoctor::Converter

    register_for 'latex'


    Asciidoctor::Extensions.register do
      preprocessor TeXPreprocessor
      preprocessor MacroInsert if (File.exist? 'macros.tex' and document.basebackend? 'html') and !(document.attributes['noteshare'] == 'yes')
      block EnvironmentBlock
      block ClickBlock
      inline_macro ChemInlineMacro
      # preprocessor ClickStyleInsert if document.attributes['click_extras'] == 'include2'
      postprocessor InjectHTML unless document.attributes['noteshare'] == 'yes'
      postprocessor EntToUni if document.basebackend? 'tex' unless document.attributes['unicode'] == 'no'
      postprocessor Chem if document.basebackend? 'html'
      postprocessor HTMLPostprocessor if document.basebackend? 'html'
      postprocessor TexPostprocessor if document.basebackend? 'tex'
    end


    Asciidoctor::Extensions.register :latex do
      # EnvironmentBlock
    end


    TOP_TYPES = %w(document section)
    LIST_TYPES = %w(dlist olist ulist)
    INLINE_TYPES = %w(inline_anchor inline_break inline_footnote inline_quoted inline_callout)
    BLOCK_TYPES = %w(admonition listing literal page_break paragraph stem pass open quote \
     example floating_title image click preamble sidebar verse toc)
    OTHER_TYPES = %w(environment table)
    NODE_TYPES = TOP_TYPES + LIST_TYPES + INLINE_TYPES + BLOCK_TYPES + OTHER_TYPES

    def initialize backend, opts
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
        warn %(Node to implement: #{node.node_name}, class = #{node.class}).magenta  if $VERBOSE
        # This warning should not be switched off by $VERBOSE
      end

    end

  end # class Converter
end # module Asciidoctor::LaTeX


class Asciidoctor::Converter::Html5Converter
  # inject our custom code into the existing Html5Converter class (Ruby 2.0 and above)
  prepend Asciidoctor::LaTeX::Html5ConverterExtensions
end

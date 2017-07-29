
#
# File: latex-converter.rb
# Author: J. Carlson (jxxcarlson@gmail.com)
# First commit: 9/26/2014
# Date: 2/20/2015
#
# OVERVIEW
#
# Asciidoctor-latex adds certain latex-like constructs to the asciidoc markup
# language and provides two backends:
#
#   - a converter with HTML as output
#
#  -- a convert with LaTeX as output
#
# The goal of this project is to be able to combine the
# strengths of asciidoc and late:
#
#  - to use asciidoc for most of the non-mathematical text
#
#  - to write inline mathematical text as one does in LaTeX:
#
#       $ a^2 + b^2 = c^1 $,
#
#    for example.
#
#  - the same for displayed mathematical text
#
#    \[
#        \int_0^1 x^n dx = \frac{1}{n+1}
#    \]
#
#  - to provide constructs which map to LaTeX environments.
#    Thus one can say
#
#    [env.theorem]
#    --
#    There are infinitely many primes
#    --
#
#     In the HTML converter the output will appear just
#     as if it had been rendered by xelatex.  If the
#     LaTeX backend is used, the output is as one would
#     expect
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
# Some documents -- those with 'click blocks',
# use a variant of the regular command:
#
#     'asciidoctor-latex -b html -a click_extras=include foo.adoc'
#
# In both cases the output is 'foo.html'
# see http://www.noteshare.io/section/homework-problems)
# for information on this topic.
#
# USAGE (2: latex)
#
# Run
#
#      'asciidoctor-latex foo.adoc'
#
# to convert foo.adoc to foo.tex.  The resulting
# file should be typeset with xelatex
# because of the likely appearance of unicode
# characters.
#
# To convert foo.tex to the latex file foo.latex,
# You can put files 'macros.tex' and 'preamble.tex' to
# replace the default preamble and set of macros.
# Define your own 'newEnvironments.tex' to use your definitions
# as opposed to the default definitions of environments
# in tex mapping to [tex.ENVIRONOMENT] in asciidoctor-latex.
#
# TECHNICAL NOTES (This section needs a thorough rewrite)
#
# This is a first step towards writing a LaTeX backend
# for Asciidoctor. It is based on the
# Dan Allen's demo-converter.rb.
#
# The main work will be in identifying asciidoc elements
# that need to be transformed and adding a method for
# each such element.  As noted below, the "warn" clause
# in the "convert" method is a useful tool for this task.
#
# Comments
#
#   1.  The "warn" clause in the converter code is quite useful.
#       For example, you may discover in running the converter on
#       "test/sample-1.adoc" that you have not implemented code for
#       the "olist" node. Thus you can work through ever more complex
#       examples to discover what you need to do to increase the coverage
#       of the converter. Hackish and ad hoc, but a process nonetheless.
#
#   2.  The converter simply passes on what it does not understand, e.g.,
#       LaTeX, This is good. However, we will have to map constructs
#       like "+\( a^2 = b^2 \)+" to $ a^2 + b^2 $, etc.
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


require 'asciidoctor'
require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'
require 'asciidoctor/converter/html5'

require 'asciidoctor/latex/css_doc_info'
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
require 'asciidoctor/latex/macro_preprocessor'
require 'asciidoctor/latex/dollar'
require 'asciidoctor/latex/tex_postprocessor'
require 'asciidoctor/latex/chem'
require 'asciidoctor/latex/sectnumoffset-treeprocessor'



# require 'asciidoctor/latex/preamble_processor'

$VERBOSE = false



module Asciidoctor::LaTeX

  # code for Html5ConverterExtension & its insertion
  # template by @mojavelinux
  module Html5ConverterExtensions

    ENV_CSS_OBLIQUE = "+++<div class='click_oblique'>+++"
    ENV_CSS_PLAIN = "+++<div class='click_plain'>+++"

    DIV_END = '+++</div>+++'
    TABLE_ROW_END = '+++</tr></table>+++'

    def info node

      warn "\n   HTMLConverter, node: #{node.node_name}".red if $VERBOSE

    end

    # Dispatches a handler for the _node_ (`NODE`)
    # based on its role.
    def environment node

      warn "entering environment(node)".red if $VERBOSE

      attrs = node.attributes

      warn "attrs['role'] = #{attrs['role']}".blue if $VERBOSE

      case attrs['role']
        when 'box', 'capsule'
          handle_null(node)
        when 'code'
          handle_code(node)
        when 'equation'
          handle_equation(node)
        when 'equationalign'
          handle_equation_align(node)
        when 'cd'
          handle_cd(node)
        when 'chem'
          handle_chem(node)
        when 'jsxgraph'
          handle_jsxgraph(node)
        when 'texmacro'
          handle_texmacro(node)
        when 'include_latex'
          handle_include_latex(node)
        else
          handle_default(node)
      end

      node.attributes['roles'] = (node.roles + ['environment']) * ' '
      self.open node
    end # method environment

    def environment_literal node

      warn "entering environment(node)".red if $VERBOSE

      attrs = node.attributes

      warn "attrs['role'] = #{attrs['role']}".blue if $VERBOSE

      case attrs['role']
        when 'box', 'capsule'
          handle_null(node)
        when 'code'
          handle_code(node)
        when 'equation'
          handle_equation_literal(node)
        when 'equationalign'
          handle_equation_align(node)
        when 'cd'
          handle_cd(node)
        when 'chem'
          handle_chem(node)
        when 'jsxgraph'
          handle_jsxgraph(node)
        when 'texmacro'
          handle_texmacro(node)
        else
          handle_default(node)
      end

      node.attributes['roles'] = (node.roles + ['environment']) * ' '
      self.open node
    end # method environment_literal

    def handle_texmacro node
      node.title = nil
      node.lines = ["+++\n\\("] + node.lines + ["\\)\n+++"]
    end

    # Example:
    # [env.include_latex]
    # --
    # \input abc.text
    # \usepackage{def}
    # --
    # Nothing appears in the HTML,
    # bu lines
    # \input abc.text
    # \usepackage{def}
    # appear in the generated tex file.
    def handle_include_latex node
      node.title = nil
      node.lines = [] # ["// "] + node.lines
      self.open node
    end

    def click node
      if node.attributes['plain-option']
        node.lines = [ENV_CSS_PLAIN] + node.lines + [DIV_END]
      else
        node.lines = [ENV_CSS_OBLIQUE] + node.lines + [DIV_END]
      end
      node.attributes['roles'] = (node.roles + ['click']) * ' '
      self.open node
    end

    def old_inline_anchor node
      target = node.target
      case node.type
        when :xref
          refid = node.attributes['refid'] || target
          # NOTE we lookup text in converter because DocBook doesn't need this logic
          text = node.text || (node.document.references[:ids][refid] || %([#{refid}]))
          # FIXME shouldn't target be refid? logic seems confused here
          %(<a href="#{target}">#{text}</a>)
        when :ref
          %(<a id="#{target}"></a>)
        when :link
          attrs = []
          attrs << %( id="#{node.id}") if node.id
          if (role = node.role)
            attrs << %( class="#{role}")
          end
          attrs << %( title="#{node.attr 'title'}") if node.attr? 'title', nil, false
          attrs << %( target="#{node.attr 'window'}") if node.attr? 'window', nil, false
          %(<a href="#{target}"#{attrs.join}>#{node.text}</a>)
        when :bibref
          %(<a id="#{target}"></a>[#{target}])
        else
          warn %(asciidoctor: WARNING: unknown anchor type: #{node.type.inspect})
      end
    end

    def inline_anchor node

      case node.type.to_s

      when 'xref'
          refid = node.attributes['refid']
          refs = node.parent.document.references[:ids]
          # FIXME: the next line is HACKISH (and it crashes the app when refs[refid]) is nil)
          # FIXME: and with the fix for nil results is even more hackish
          if !node.text && refid && refs[refid]
            reftext = refs[refid].gsub('.', '')
            reftext = reftext.gsub(/:.*/,'')
            if refid =~ /\Aeq-/
              output = "<span class='xref'><a href=\##{refid}>equation #{reftext}</a></span>"
            elsif refid =~ /\Aformula-/
              output = "<span class='xref'><a href=\##{refid}>formula #{reftext}</a></span>"
            elsif refid =~ /\Areaction-/
              output = "<span class='xref'><a href=\##{refid}>reaction #{reftext}</a></span>"
            else
              output = "<span class='xref'><a href=\##{refid}>#{reftext}</a></span>"
            end
          else
            output = "<span class='xref'>" + old_inline_anchor(node) + "</span>"
          end
      else
        output = old_inline_anchor node
      end
      output
    end

    def handle_equation(node)
      attrs = node.attributes
      options = attrs['options']
      node.title = nil
      number_part = '<td class="equation_number_style">' + "(#{node.caption}) </td>"
      number_part = ["+++ #{number_part} +++"]
      equation_part = ['+++<td class="equation_content_style";>+++'] + ['\\['] + node.lines + ['\\]'] + ['+++</td>+++']
      table_style='class="equation_table_style"'
      row_style='class="equation_row_style"'
      if options.include? 'numbered'
        node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + number_part + [TABLE_ROW_END]
      else
        node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + [TABLE_ROW_END]
      end
    end

    def handle_equation_literal(node)
      attrs = node.attributes
      options = attrs['options']
      node.title = nil
      number_part = '<td class="equation_number_style">' + "(#{node.caption}) </td>"
      equation_part = ['<td class="equation_content_style";>'] + ['\\['] + node.lines + ['\\]'] + ['</td>']
      table_style='class="equation_table_style"'
      row_style='class="equation_row_style"'
      if options.include? 'numbered'
        node.lines =  ["<table #{table_style}><tr #{row_style}>"] + equation_part + number_part + ['</tr></table>']
      else
        node.lines =  ["<table #{table_style}><tr #{row_style}>"] + equation_part + ['</tr></table>']
      end
    end

    def handle_equation_align(node)
      attrs = node.attributes
      options = attrs['options']
      node.title = nil
      number_part = '<td class="equation_number_style">' + "(#{node.caption}) </td>"
      number_part = ["+++ #{number_part} +++"]
      equation_part = ['+++<td class="equation_content_style";>+++'] + ['\\[\\begin{split}'] + node.lines + ['\\end{split}\\]'] + ['+++</td>+++']
      table_style='class="equation_table_style" '
      row_style='class="equation_row_style"'
      if options.include? 'numbered'
        node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + number_part + [TABLE_ROW_END]
      else
        node.lines =  ["+++<table #{table_style}><tr #{row_style}>+++"] + equation_part + [TABLE_ROW_END]
      end
    end

    def handle_cd(node)
      node.title = nil
      node.lines  = ['\\[', '\require{AMScd}', '\\begin{CD}', node.lines, '\\end{CD}', '\\]']
    end

    def handle_chem(node)
      node.title = nil
      number_part = '<td class="equation_number_style">' + "(#{node.caption}) </td>"
      number_part = ["+++ #{number_part} +++"]
      equation_part = ['+++<td class="equation_content_style">+++'] + [' \\[\\ce{' + node.lines[0] + '}\\] '] + ['+++</td>+++']
      table_style='class="equation_table_style"'
      row_style='class="equation_row_style"'
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

    def handle_code(node)
      warn "handle code".red  if $VERBOSE
      if node.attributes['id'].nil?
        node.title = 'FOO'
        node.caption = '666'
      end
    end

    def handle_default(node)
        if node.attributes['plain-option']
          node.lines = [ENV_CSS_PLAIN] + node.lines + [DIV_END]
        else
          node.lines = [ENV_CSS_OBLIQUE] + node.lines + [DIV_END]
        end
    end

  end
  # END OF Html5ConverterExtensions

  class Converter
    include Asciidoctor::Converter

    register_for 'latex'

    # puts "HOLA!".red

    # Note: invoke asciidoctor-latex by
    #
    #   asciidoctor-latex -a dialect=asciidoc foo.adoc
    #   asciidoctor-latex -a dialect=manuscript foo.adoc
    #   asciidoctor-latex -a dialect=latex foo.adoc
    #
    # These are source file options: for plain asciidoc,
    # asciidoc-manuscript, and asciidoc-latex
    Asciidoctor::Extensions.register do

      dialect = document.options['dialect'] || document.attributes['dialect'] || 'latex'

      # puts "DIALECT = #{dialect}".red

      if ['asciidoc', 'manuscript'].include? dialect

        preprocessor DollarPreprocessor if document.basebackend? 'tex'

      end

      if ['latex', 'manuscript'].include? dialect
        preprocessor ClickStyleInsert if document.attributes['css_extras'] == 'include'
        preprocessor MacroPreprocessor

        block EnvironmentBlock
        block EnvironmentBlock2
        block ClickBlock

        inline_macro GlossInlineMacro
        inline_macro IndexTermInlineMacro

        postprocessor InjectHTML unless document.attributes['inject_javascript'] == 'no'
        postprocessor EntToUni if document.basebackend? 'tex' unless document.attributes['unicode'] == 'no'

        docinfo_processor CSSDocinfoProcessor
      end

      if ['latex'].include? dialect
        preprocessor TeXPreprocessor unless document.attributes['preprocess'] == 'no'
        preprocessor MacroInsert if (File.exist? 'macros.tex')

        inline_macro ChemInlineMacro
        block_macro IncludeLatexBlockMacro

        postprocessor Chem if document.basebackend? 'html'
        postprocessor HTMLPostprocessor if document.basebackend? 'html'
        postprocessor TexPostprocessor if document.basebackend? 'tex'
      end

    end

    Asciidoctor::Extensions.register :latex do
      # EnvironmentBlock
    end


    TOP_TYPES = %w(document section)
    LIST_TYPES = %w(dlist olist ulist)
    INLINE_TYPES = %w(inline_anchor inline_break inline_footnote inline_quoted inline_callout inline_indexterm)
    BLOCK_TYPES = %w(admonition listing literal page_break paragraph stem pass open quote \
     example floating_title image click preamble sidebar verse toc)
    OTHER_TYPES = %w(environment environment_literal table)
    NODE_TYPES = TOP_TYPES + LIST_TYPES + INLINE_TYPES + BLOCK_TYPES + OTHER_TYPES

    def initialize backend, opts
      super
      basebackend 'tex'
      outfilesuffix '.tex'
    end

    # FIXME: find a solution without a global variable
    $latex_environment_names = []

    # FIXME: this should be retired -- still used
    # in click blocks but no longer in env blocks
    $label_counter = 0

    def convert node, transform = nil

      if NODE_TYPES.include? node.node_name
        node.tex_process
      else
        warn %(Node to implement: #{node.node_name}, class = #{node.class}).magenta  # if $VERBOSE
        # This warning should not be switched off by $VERBOSE
      end

    end

  end # class Converter
end # module Asciidoctor::LaTeX


class Asciidoctor::Converter::Html5Converter
  # inject our custom code into the existing Html5Converter class (Ruby 2.0 and above)
  # the ideal is to use 'prepend'; however, this is incompatible
  # with the current version of Opal, so the alternative of 'include' is provided for
  # cases in which 'prepend' is not available
  if respond_to? :prepend
    prepend Asciidoctor::LaTeX::Html5ConverterExtensions
  else
    include Asciidoctor::LaTeX::Html5ConverterExtensions
  end
  # include Asciidoctor::LaTeX::Html5ConverterExtensions
end

require 'asciidoctor'
require 'asciidoctor/latex/core_ext/colored_string'
require 'asciidoctor/latex/core_ext/utility'

module TexUtilities

  def self.braces(*args)
    args.map{|arg| "\{#{arg}\}"}.join("")
  end

  def self.macro(name, *args)
    "\\#{name}#{braces *args}"
  end

  def self.macro_opt(name, opt, *args)
    "\\#{name}[#{opt}]#{braces *args}"
  end

  # tex.region('bf', 'foo bar') => {\bf foo bar}
  def self.region(name, *args)
    "\{\\#{name} #{args.join(" ")}\}"
  end

  def self.apply_macros(macro_list, arg)
    val = arg
    macro_list.reverse.each do |macro_name|
      val = self.macro(macro_name, val)
    end
    val
  end

  def self.begin(arg)
    macro('begin', arg)
  end

  def self.end(arg)
    macro('end', arg)
  end

  def self.env(env, *args)
    body = args.pop
    "#{self.begin(env)}#{braces *args}\n#{body}\n#{self.end(env)}"
  end

  def self.env_opt(env, opt, *args)
    body = args.pop
    "#{self.begin(env)}[#{opt}]#{braces *args}\n#{body}\n#{self.end(env)}"
  end

  # normalize the name because it is an id
  # and so frequently contains underscores
  def self.hypertarget(name, text)
    if text
     # text = text.rstrip.chomp
    end
    if name
      "\\hypertarget\{#{name.tex_normalize}\}\{#{text}\}"
    else
      "\\hypertarget\{'NO-ID'\}\{#{text}\}"
      # FIXME: why do we need this branch?
    end
  end


end

# Yuuk!, The classes in node_processor implement the
# latex backend for Asciidoctor-latex.  This
# module is far from complete.
module Asciidoctor


  include TexUtilities
  $tex = TexUtilities

  class Document

    # Write preamble for tex file, write closing
    # \end{document}
    #
    # This method reads several files:
    #
    # - preamble: required boilerplate
    #
    # - asciidoc_tex_macros: needed to translate certain
    #   asciidoc constructs, e.g., quotes, into tex
    #   construct -- one TeX defintion per asciidoc construct
    #
    # - macros: supplied by the user.  We need a good
    #   mechanism for identifying and reading the user's
    #   macro definitions.  In noteshare there is a database
    #   field
    #


    def tex_process

      doc = ''

      unless embedded? or document.attributes['header']=='no'
        doc << "%% Preamble %%\n"
        if File.exist? 'preamble.tex'
          preamble = IO.read('preamble.tex')
          doc << preamble << "\n "
        else
          doc << File.open(File.join(LaTeX::DATA_DIR, "preamble_#{self.document.doctype}.tex"), 'r') { |f| f.read }
        end
        doc << "%% Asciidoc TeX Macros %%\n"
        doc << File.open(File.join(LaTeX::DATA_DIR, 'asciidoc_tex_macros.tex'), 'r') { |f| f.read }
        doc << "%% User Macros %%\n"
        # doc << File.open(File.join(LaTeX::DATA_DIR, 'macros.tex'), 'r') { |f| f.read }
        if File.exist? 'macros.tex'
          macros = IO.read('macros.tex')
          doc << macros
        else
          # warn "Could not find file macros.tex".yellow
        end
        if File.exist?('myEnvironments.tex')
          doc << "\\input myEnvironments.tex\n"
        else
          # warn "I will take input from newEnvironments.tex".blue
          # doc << "\\input newEnvironments.tex\n"
        end

        doc << "%% Front Matter %%"
        doc << "\n\n\\title\{#{self.doctitle}\}\n"
        doc << "\\author\{#{self.author}\}\n"
        doc << "\\date\{#{self.revdate}\}\n\n\n"
        doc << "%% Begin Document %%"
        # doc << "\n\n\\begin\{document\}\n"
        doc << "\n\n\\begin\{document\}\n"
        doc << "\\maketitle\n"
        if self.attributes['toc-placement']=="auto"
          doc << "\\tableofcontents\n"
        end
      end



      processed_content = LaTeX::TeXBlock.process_environments self.content
      doc << processed_content

      unless embedded?
        # Now write the definitions of the new environments
        # discovered to file
        definitions = ""

        $latex_environment_names.uniq.each do |name|
          definitions << "\\newtheorem\{#{name}\}\{#{name.capitalize}\}" << "\n"
        end

        File.open('newEnvironments.tex', 'w') { |f| f.write(definitions) }

        # Output
        doc << "\n\\end{document}\n" unless document.attributes['header']=='no'
      end

      doc << "\n"
    end
  end

  # Write TeX for each of five levels of Ascidoc section,
  # .e.g. \section{Introduction} for == Introduction
  class Section

    def tex_process
      doctype = self.document.doctype

      tags = { 'article' => [ 'part',  'section', 'subsection', 'subsubsection', 'paragraph' ],
               'book' => [ 'part', 'chapter', 'section', 'subsection', 'subsubsection', 'paragraph' ] }

      tagname = tags[doctype][self.level]
      tagsuffix = self.numbered ? '' : '*'
      id ="_#{self.title.downcase.gsub(' ', '_')}"
      heading = "\\#{tagname}#{tagsuffix}\{#{self.title}\}"
      heading = $tex.hypertarget id, heading

      if self.sectname == 'index'
        value = $tex.macro 'renewcommand', '\\indexname', self.title
        value += $tex.hypertarget id, '\\printindex'
      else
        value = "#{heading}\n#{self.content}"
      end

      value
    end
  end


  # Write TeX \itemize or \enumerate lists
  # for ulist and olist.  Recurses for
  # nested lists.
  class List

    def tex_process
      case self.node_name
      when 'dlist'
        dlist_process
      when 'ulist'
        ulist_process
      when 'olist'
        olist_process
      else
        # warn "This Asciidoctor::List, tex_process.  I don't know how to do that (#{self.node_name})" if $VERBOSE
      end
    end

    def dlist_process
      list = "\\begin{description}\n\n"
      self.items.each do |terms, dd|
        list << "\\item["
        [*terms].each do |dt|
        # warn ["  --  item: ".blue, "#{dt.text}"].join(" ") if $VERBOSE
          list << dt.text
        end
        list << "]"
        if dd
          list << dd.text << "\n\n" if dd.text?
          list << dd.content << "\n" if dd.blocks?
        end
      end
      list << "\\end{description}\n\n"
    end

    def ulist_process
      list = "\\begin{itemize}\n\n"
      self.content.each do |item|
        list << "\\item #{item.text}\n\n"
        list << item.content
      end
      list << "\\end{itemize}\n\n"
    end

    def olist_process
      list = "\\begin{enumerate}\n\n"
      self.content.each do |item|
        list << item.text.macro('item') << "\n\n"
        list << item.content
      end
      list << "\\end{enumerate}\n\n"
    end

  end

  # Proces block elements of varios kinds
  class Block

    # STANDARD_ENVIRONMENT_NAMES = %w(theorem proposition lemma definition example problem equation)
    STANDARD_ENVIRONMENT_NAMES = %w(equation)

    def tex_process
      case self.blockname
      when :paragraph
        paragraph_process
      when :stem
        stem_process
      when :admonition
        admonition_process
      when :page_break
        page_break_process
      when :literal
        self.literal_process
      when :pass
        self.pass_process
      when :quote
        self.quote_process
      when :open
        self.open_process
      when :environment
        self.environment_process
      when :click
        self.click_process
      when :listing
        self.listing_process
      when :example
        self.example_process
      when :floating_title
        self.floating_title_process
      when :image
        self.image_process
      when :preamble
        self.preamble_process
      when :sidebar
        self.sidebar_process
      when :verse
        self.verse_process
      when :toc
        self.toc_process
      # when :table
        # self.table_process
      else
        # warn "This is Asciidoctor::Block, tex_process.  I don't know how to do that (#{self.blockname})" if $VERBOSE if $VERBOSE
        ""
      end
    end


    def paragraph_process
      options = self.attributes['options']
      out = ""
      if self.title?
        title = "#{self.title}\."
        out << $tex.region('bf', title) + ' '
      end
      content =  LaTeX::TeXPostProcess.make_substitutions(self.content)
      if role == "red"
        content = content.macro('rolered')
      elsif role == "blue"
        content = content.macro('roleblue')
      end
      if options and options.include? 'hardbreaks'
        # content =  content.macro('obeylines')
      end

      out << content << "\n\n"
    end

    def stem_process
      environment = LaTeX::TeXBlock.environment_type self.content
      if LaTeX::TeXBlock::INNER_TYPES.include? environment
        "\\\[\n#{LaTeX::TeXPostProcess.stem_substitutions self.content}\n\\\]\n"
      else
        self.content
      end
    end

    def admonition_process
      $tex.macro 'admonition', self.style, self.content
    end

    def page_break_process
      "\n\\vfill\\eject\n"
    end

    def literal_process
      heading = ''
      if id and self.title
        heading = $tex.hypertarget id, self.title
      elsif self.title
        heading = self.title
      end
      if heading == ''
        $tex.env 'verbatim', self.content
      else
        output = $tex.region 'bf', heading
        output << "\\vspace\{-1\\baselineskip\}\n"
        output << ($tex.env 'verbatim', self.content)
      end
    end

    def pass_process
      self.content
    end

    def quote_process
      if self.attr? 'attribution'
        attribution = self.attr 'attribution'
        citetitle = (self.attr? 'citetitle') ? (self.attr 'citetitle') : nil
        # citetitle = citetitle ? ' - ' + citetitle : ''
        citetitle = citetitle ? $tex.region('bf', citetitle) + ' \\\\' : ''
        $tex.env 'aquote', attribution, citetitle, self.content
      elsif self.title
        $tex.env 'tquote', self.title, self.content
      else
        $tex.env 'quotation', self.content
      end
    end



 ####################################################################

    def label
      if self.id
        label = $tex.macro 'label', self.id
        # label = $tex.macro 'label', $tex.hypertarget(self.id, self.id)
      else
        label = ""
      end
      label
    end

    def options
      self.attributes['options']
    end

    def env_title
      if self.attributes['original_title']
        "\{\\rm (#{self.attributes['original_title']}) \}"
      else
        ''
      end
    end

 ####################################################################

    def label_line
      if label == ""
        ""
      else
        label + "\n"
      end
    end

    def handle_listing
      content = $tex.env 'verbatim', self.content
      $tex.env env, label, content
    end

    def handle_eqalign
      content = $tex.env 'aligned', "#{label_line}#{self.content.strip}"
      if options.include? 'numbered'
        $tex.env 'align', content
      else
        $tex.env 'align*', content
      end
    end

    def handle_equation
      if options.include? 'numbered'
        content = $tex.hypertarget self.id, self.content.strip
        $tex.env 'equation', "#{label_line}#{content}"
      else
        $tex.env 'equation*', "#{label_line}#{self.content.strip}"
      end
    end

    def handle_chem
      $tex.env 'equation', "#{label_line}\\ce\{#{self.content.strip}\}\n"
    end

    def handle_plain(env)

      if self.id and self.title
        _title = $tex.hypertarget self.id, self.env_title
      else
        _title = self.env_title
      end

      if self.attributes['plain-option']
        content = $tex.region 'rm', self.content.rstrip
      else
        content = self.content.rstrip
      end

      $tex.env env, "#{_title}#{label_line}#{content}\n"
    end

 ####################################################################

    def environment_process

      env = self.attributes["role"]

      # record any environments encountered but not built=in
      if !STANDARD_ENVIRONMENT_NAMES.include? env and !$latex_environment_names.include? env
        $latex_environment_names << env
      end

      case env
        when 'listing'
          handle_listing
        when 'equationalign'
          handle_eqalign
        when 'equation'
          handle_equation
        when 'chem'
          handle_chem
        when 'box'
          handle_box
        when 'texmacro'
          handle_texmacro
        when 'include_latex'
          handle_include_latex
        else
          handle_plain(env)
      end
    end

    def handle_texmacro
      "%% User tex macros:\n#{self.content}\n%% end of user macros\n"
    end

   # Example:
   # [env.include_latex]
   # --
   # \nput abc.text
   # \usepackage{def}
   # --
   # Nothing appears in the HTML,
   # bu lines
   # \nput abc.text
   # \usepackage{def}
   # appear in the generated tex file.
    def handle_include_latex
      puts "Hi Boss, it's me again!"
      puts self.content
      puts "---------------"
      self.content
    end

    def handle_box
      if self.title.nil? or self.title == ''
        $tex.env 'asciidocbox', self.content
      else
        $tex.env 'titledasciidocbox',  self.title, self.content
      end
    end

    def click_process
      attr = self.attributes
      click = self.attributes["role"]
      # record any environ$ments encounted but not built=in
      if !STANDARD_ENVIRONMENT_NAMES.include? click
        $latex_environment_names << click
      end

      if title
        title = self.title.downcase
      end

      # original_title = title.split(' ')[0].downcase
      # FIXME: the above is  work-around: instead set
      # originaltitle in clickblock

      if attr['plain-option']
        content = $tex.region 'rm', self.content
      else
        content = $tex.region 'it', self.content
      end

      # FIXME! This is a temporary hack.
      # attr['original_title'] can be nil --
      # it shouldn't be
      if attr['original_title']
        if attr['options'] and attr['options'].include? 'numbered'
          env = attr['original_title'].downcase
        else
          env =  attr['original_title'].downcase+'*'
        end
      else
        env = 'click'
      end



      if self.id == nil # No label
        $tex.env env, content
      else
        label = $tex.macro 'label', self.id
        $tex.env env, "#{label}\n#{content}"
      end
    end

    def toc_process
      if document.attributes['toc-placement'] == 'macro'
        $tex.macro 'tableofcontents'
      end
      # warn "Please implement me! (toc_process)".red if $VERBOSE
    end

    def report
      # Report on this node
      warn ["OPEN BLOCK:".magenta, "id: #{self.id}"].join(" ")
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ")
      warn ["Attributes:".magenta, "#{self.attributes}".cyan].join(" ")
      warn ["Title: ".magenta, title.cyan, "style:", self.style].join(" ") if title
      warn ["Content:".magenta, "#{self.content}".yellow].join(" ")
      warn ["Style:".green, "#{self.style}".red].join(" ")
      # warn ["METHODS:".red, "#{self.methods}".yellow].join(" ")
    end


    # Process open blocks.  Map a block of the form
    #
    # .Foo
    # [[hocus_pocus]]
    # --
    # La di dah
    # --
    #
    # to
    #
    # \begin{Foo}
    # \label{hocus_pocus}
    # La di dah
    # \end{Foo}
    #
    # This scheme enables one to map Asciidoc blocks to
    # LaTeX environments with essentally no knoweldge
    # of either other than their form.
    #
    def open_process

      attr = self.attributes

      # Get title !- nil or make a dummy one
      title = self.title? ? self.title : 'Dummy'

      # strip constructs like {counter:theorem} from the title
      title = title.gsub /\{.*?\}/, ""
      title = title.strip

      if attr['role'] == 'text-center'
        $tex.env 'center', self.content
      else
        self.content
      end

    end

    def listing_process
      "\\begin\{verbatim\}\n#{self.content}\n\\end\{verbatim\}\n"
    end

    def example_process
      id = self.attributes['id']
      if self.title
        heading = $tex.region 'bf', self.title
        content  = "-- #{heading}.\n#{self.content}"
      else
        content = self.content
      end
      if id
        hypertarget = $tex.hypertarget id, self.content.split("\n")[0]
        content = "#{hypertarget}\n#{content}" if id
      end
      $tex.env 'example', content
    end


    def floating_title_process
      doctype = self.document.doctype

      tags = { 'article' => [ 'part',  'section', 'subsection', 'subsubsection', 'paragraph' ],
               'book' => [ 'part', 'chapter', 'section', 'subsection', 'subsubsection', 'paragraph' ] }

      tagname = tags[doctype][self.level]

      "\\#{tagname}*\{#{self.title}\}\n\n#{self.content}\n\n"
    end

    def image_process
      if self.attributes['width']
        width = "#{self.attributes['width'].to_f/100.0}truein"
      else
        width = '2.5truein'
      end
      raw_image = self.attributes['target']
      unless (imagesdir = document.attr 'imagesdir').nil_or_empty?
        raw_image = ::File.join imagesdir, raw_image
      end
      if document.attributes['noteshare'] == 'yes'
        image_rx = /image.*original\/(.*)\?/
        match_data = raw_image.match image_rx
        if match_data
          image = match_data[1]
        else
          image = "undefined"
        end
      else
        image = raw_image
      end
      if self.title?
        caption = "\\caption\{#{self.title}\}"
      else
        caption = ''
      end
      refs = self.parent.document.references  # [:ids]
      if self.attributes['align'] == 'center'
        align = '\\centering'
      else
        align = ''
      end
      float = self.attributes['float']
      if float
        figure_type = 'wrapfigure'
        ftext_width = width # '0.45\\textwidth'
        caption=''
      else
        figure_type = 'figure'
        text_width = ''
      end
      case float
      when 'left'
        position = '{l}'
      when 'right'
        position = '{r}'
      else
        position = '[h]'
      end
      # pos_option = "#{figure_type}}#{position}"
      # incl_graphics = $tex.macro_opt, "width=#{width}", image
      # $tex.env figure_type, "#{pos_option}\{#{ftext_width}\}", incl_graphics,
      #\n\\includegraphics[width=#{width}]{#{image}}\n#{caption}\n#{align}"
      "\\begin{#{figure_type}}#{position}\{#{ftext_width}\}\n\\centering\\includegraphics[width=#{width}]{#{image}}\n#{caption}\n#{align}\n\\end{#{figure_type}}\n"
    end

    def preamble_process
      # "\\begin\{preamble\}\n%% HO HO HO!\n#{self.content}\n\\end\{preamble\}\n"
      self.content
    end


    def sidebar_process
      title = self.title
      attr = self.attributes
      id = attr['id']
      if id
        content = "\\hypertarget\{#{id}\}\{#{self.content.rstrip}\}"
      else
        content = self.content
      end
      if title
        title  = $tex.env 'bf', title
        $tex.env 'sidebar', "#{title}\n#{content.rstrip}"
      else
        $tex.env 'sidebar', content
      end
    end

    def verse_process
      # $tex.env 'alltt', self.content
      $tex.env 'verse', self.content
    end

  end # class Block

  # Process inline elements
  class Inline

    def tex_process
      case self.node_name
      when 'inline_quoted'
        self.inline_quoted_process
      when 'inline_anchor'
        self.inline_anchor_process
      when 'inline_break'
        self.inline_break_process
      when 'inline_footnote'
        self.inline_footnote_process
      when 'inline_callout'
        self.inline_callout_process
      when 'inline_indexterm'
        self.inline_indexterm_process
      else
        ""
      end
    end

    def inline_quoted_process
      # warn "THIS IS: inline_quoted_process: #{self.type}"  if $VERBOSE
      case self.type
        when :strong
          "\\textbf\{#{self.text}\}"
        when :emphasis
          "\\emph\{#{self.text}\}"
        when :asciimath
          output = Asciidoctor.convert( self.text, backend: 'html')
          output
        when :monospaced
          "\\texttt\{#{self.text}\}"
        when :superscript
          "$\{\}^{#{self.text}}$"
        when :subscript
          "$\{\}_{#{self.text}}$"
        when :mark
          "\\colorbox\{yellow\}\{ #{self.text}\}"
        when :double
          "``#{self.text}''"
        when :single
          "`#{self.text}'"
        when :latexmath
           "\\(#{LaTeX::TeXPostProcess.stem_substitutions self.text}\\)"
          # output = Asciidoctor.convert self.text, {stem: 'asciimath', backend: 'html'}
          self.text
        when :unquoted
          role = self.attributes["role"]
          if role == "red"
            "\\rolered\{ #{self.text}\}"
          elsif role == "blue"
            "\\roleblue\{ #{self.text}\}"
          else
            # warn "This is inline_quoted_process.  I don't understand role = #{role}" if $VERBOSE
          end
        when :literal
          "\\texttt\{#{self.text}\}"
        when :verse
          "\\texttt\{#{self.text}\}"
        else
          "\\unknown:#{self.type}\\{#{self.text}\\}"
      end
    end

    def inline_anchor_process

      refid = self.attributes['refid']
      refs = self.parent.document.references[:ids]
      # FIXME: the next line is HACKISH (and it crashes the app when refs[refid]) is nil)
      # FIXME: and with the fix for nil results is even more hackish
      # if refs[refid]
      if !self.text && refs[refid]
        reftext = refs[refid].gsub('.', '')
        m = reftext.match /(\d*)/
        if m[1] == reftext
          reftext = "(#{reftext})"
        end
      else
        reftext = self.text
      end
      case self.type
        when :link
          $tex.macro 'href', self.target, self.text
        when :ref
          $tex.macro 'label', (self.id || self.target)
        when :xref
          $tex.macro 'hyperlink', refid.tex_normalize, reftext
        else
          # warn "!!".magenta if $VERBOSE
      end
    end

    def inline_break_process
      "#{self.text} \\\\"
    end

    def inline_footnote_process
      $tex.macro 'footnote', self.text
    end

    def inline_callout_process
      # warn "Please implement me! (inline_callout_process)".red if $VERBOSE
    end

    def inline_indexterm_process
      case self.type
      when :visible
        output = $tex.macro 'index', self.text
        output += self.text
      else
        $tex.macro 'index', self.attributes['terms'].join('!')
      end
    end

  end

  class Table

    def tex_process
      # # warn "This is Asciidoctor::Table, tex_process.  I don't know how to do that".yellow +  " (#{self.node_name})".magenta if $VERBOSE
      # table = Table.new self.parent, self.attributes
      n_rows = self.rows.body.count
      n_columns = self.columns.count
      alignment = (['c']*n_columns).join('|')
      output = "\\begin\{center\}\n"
      output << "\\begin\{tabular\}\{|#{alignment}|\}\n"
      output << "\\hline\n"
      self.rows.body.each_with_index do |row, index|
        row_array = []
        row.each do |cell|
          if Array === (cell_content = cell.content)
            row_array << cell_content.join("\n")
          else
            row_array << cell_content
          end
        end
        output << row_array.join(' & ')
        output << " \\\\ \n"
      end
      output << "\\hline\n"
      output << "\\end{tabular}\n"
      output << "\\end{center}\n"
      "#{output}"
  end


  end


  module LaTeX
    # TeXPostProcess cleans up undesired transformations
    # inside the TeX environment.  Strings
    # &ampp;, &gt;, &lt; are mapped back to
    # &, >, < and \\ is conserved.
    module TeXPostProcess

      def self.match_inline str
        rx_tex_inline = /\$(.*?)\$/
        str.scan rx_tex_inline
      end

      def self.match_block str
        rx_tex_block = /\\\[(.*?)\\\]/m
        str.scan rx_tex_block
      end

      def self.make_substitutions1 str
        str = str.gsub("&amp;", "&")
        str = str.gsub("&gt;", ">")
        str = str.gsub("&lt;", "<")
      end

      def self.make_substitutions_in_matches matches, str
        matches.each do |m|
          m_str = m[0]
          m_transformed = make_substitutions1 m_str
          str = str.gsub(m_str,m_transformed)
        end
        str
      end

      # (1) & (2) are needed together to protect \\
      # inside of matrices, etc.
      def self.make_substitutions str
        str = str.gsub('\\\\', '@@')   # (1)
        matches = match_inline str
        if matches.count > 0
          str = make_substitutions_in_matches matches, str
        end
        matches = match_block str
        if matches.count > 0
          str = make_substitutions_in_matches matches, str
        end
        str = str.tr('@','\\')         # (2)
        str
      end

      def self.stem_substitutions str
        str = str.gsub('\\\\', '@@')   # (1)
        str = make_substitutions1 str
        str = str.tr('@','\\')         # (2)
        str
      end

    end
  end
end

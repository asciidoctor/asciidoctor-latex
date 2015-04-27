require 'asciidoctor'
require 'asciidoctor/latex/core_ext/colored_string'
require 'asciidoctor/latex/core_ext/utility'


module TexUtilities

  def self.macro(name, *args)
    case args.count
      when 1
        "\\#{name}\{#{args[0]}\}"
      when 2
        "\\#{name}\{#{args[0]}\}\{#{args[1]}\}"
      when 3
        "\\#{name}\{#{args[0]}\}\{#{args[1]}\}\{#{args[2]}\}"
      else
        ''
    end
  end

  # tex.region('bf', 'foo bar') => {\bf foo bar}
  def self.region(name, arg)
    "\{\\#{name} #{arg}\}"
  end


  def self.macro_opt(name, opt, args)
    case args.count
      when 1
        "\\#{name}[#{opt}]\{#{args[0]}\}"
      when 2
        "\\#{name}[#{opt}]\{#{args[0]}\}\{#{args[1]}\}"
      when 3
        "\\#{name}[#{opt}]\{#{args[0]}\}\{#{args[1]}\}\{#{args[2]}\}"
      else
        ''
    end
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
    case args.count
      when 1
        "#{self.begin(env)}\n#{args[0].strip}\n#{self.end(env)}\n\n"
      when 2
        "#{self.begin(env)}\{#{args[0]}\}\n#{args[1]}\n#{self.end(env)}\n\n"
      when 3
        "#{self.begin(env)}\{#{args[0]}\}\{#{args[1]}\}\n#{args[2]}\n#{self.end(env)}\n\n"
      else
        ''
    end
  end

  def self.hypertarget(name, text)
    "\\hypertarget\{#{name}\}\{#{text}\}"
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
      # warn "Node: #{self.class}".blue if $VERBOSE

      doc = ''

      # # warn "document.attributes['header'] = #{document.attributes['header']}".magenta if $VERBOSE

      unless embedded? or document.attributes['header']=='no'
        doc << "%% Preamble %%\n"
        if File.exist? 'preamble.tex'
          preamble = IO.read('preamble.tex')
          # warn "preamble: #{preamble.length} chars".yellow
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
          # warn "macros: #{macros.length} chars".yellow
          doc << macros
        else
          # warn "Could not find file macros.tex".yellow
        end
        if File.exist?('myEnvironments.tex')
          # warn "I will take input from myEnvironments.tex".blue
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
        if self.attributes["toc"]
          doc << "\\tableofcontents\n"
        end
      end



      processed_content = LaTeX::TeXBlock.process_environments self.content
      doc << processed_content

      unless embedded?
        # Now write the defnitions of the new environments
        # discovered to file
        # warn "Writing environment definitions to file: newEnvironments.tex" if $VERBOSE
        definitions = ""

        $latex_environment_names.uniq.each do |name|
          # warn name if $VERBOSE
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
      # warn ["Node:".blue, "section[#{self.level}]:".cyan, "#{self.title}"].join(" ") if $VERBOSE
      doctype = self.document.doctype

      tags = { 'article' => [ 'part',  'section', 'subsection', 'subsubsection', 'paragraph' ],
               'book' => [ 'part', 'chapter', 'section', 'subsection', 'subsubsection', 'paragraph' ] }

      tagname = tags[doctype][self.level]
      tagsuffix = self.numbered ? '' : '*'
      id ="_#{self.title.downcase.gsub(' ', '_')}"

      # "\\#{tagname}#{tagsuffix}\{#{self.title}\}\n\n#{self.content}\n\n"

      heading = "\\#{tagname}#{tagsuffix}\{#{self.title}\}"
      hypertarget = $tex.hypertarget id, self.content.split("\n")[0]
      "#{heading}\n#{hypertarget}\n#{self.content}"

    end
  end


  # Write TeX \itemize or \enumerate lists
  # for ulist and olist.  Recurses for
  # nested lists.
  class List

    def tex_process
      # warn ["Node:".blue, "#{self.node_name}[#{self.level}]".cyan, "#{self.content.count} items"].join(" ") if $VERBOSE
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
        # warn ["  --  item: ".blue, "#{item.text.split("\n").first}"].join(" ") if $VERBOSE
        list << "\\item #{item.text}\n\n"
        list << item.content
      end
      list << "\\end{itemize}\n\n"
    end

    def olist_process
      list = "\\begin{enumerate}\n\n"
      self.content.each do |item|
        # warn ["  --  item:  ".blue, "#{item.text.split("\n").first}"].join(" ") if $VERBOSE
        # list << "\\item #{item.text}\n\n"
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
      # warn ["Node:".blue , "#{self.blockname}".blue].join(" ") if $VERBOSE
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
      if self.attributes['title']
        title = "#{self.attributes['title']}\."
        out << title.macro('bf')
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
      warn "literal_process, attributes = #{self.attributes}".yellow
      if self.title
        heading = $tex.region 'bf', self.title
      else
        heading = ""
      end
      if id and self.title
        heading = $tex.hypertarget id, heading
        heading += "\\vglue-1.5em"
      end
       content = $tex.env 'verbatim', self.content
      "#{heading}\n#{content}"

    end

    def pass_process
      self.content
    end

    def quote_process
      if self.attr? 'attribution'
        attribution = self.attr 'attribution'
        citetitle = (self.attr? 'citetitle') ? (self.attr 'citetitle') : nil
        citetitle = citetitle ? ' - ' + citetitle : ''
        $tex.env 'aquote', attribution, citetitle, self.content
      else
        $tex.env 'quote', self.content
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

    def handle_listing
      content = $tex.env 'verbatim', self.content
      $tex.env env, label, content
    end

    def handle_eqalign
      if options.include? 'numbered'
        content = $tex.env 'split', label + "\n" + self.content.strip
        $tex.env 'equation', content
      else
        content = $tex.env 'split', label + "\n" + self.content.strip
        $tex.env 'equation*', content
      end
    end

    def handle_equation
      if options.include? 'numbered'
        content = $tex.hypertarget self.id, self.content.strip
        $tex.env 'equation', "#{label}#{content}"
      else
        $tex.env 'equation*', "#{label}#{self.content.strip}"
      end
    end

    def handle_chem
      $tex.env 'equation', "#{label}\n\\ce\{#{self.content.strip}\}\n"
    end

    def handle_plain(env)
      if self.attributes['plain-option']
        content = $tex.macro 'rm', self.content
        $tex.env env, "#{env_title}#{label}#{content}\n"
        # output = "\\begin\{#{env}\}#{title}#{label}\n#{self.content}\n\\end\{#{env}\}\n"
      else
        $tex.env env, "#{env_title}#{label}#{self.content}\n"
        # output = "\\begin\{#{env}\}#{title}#{label}\\rm\n#{self.content}\n\\end\{#{env}\}\n"
      end
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
        else
          handle_plain(env)
      end
    end

    def click_process

      click = self.attributes["role"]
      # record any environments encounted but not built=in
      if !STANDARD_ENVIRONMENT_NAMES.include? click
        $latex_environment_names << click
      end

      ### XXX fixme:
      click = 'note'

      if self.id == nil # No label
        $tex.env 'click', self.content
      else
        label = $tex.macro 'label', self.id
        $tex.env 'click', "#{label}\n#{self.content}"
      end
    end

    def toc_process
      # warn "Please implement me! (toc_process)".red if $VERBOSE
    end

    def report
      # Report on this node
      # warn ["OPEN BLOCK:".magenta, "id: #{self.id}"].join(" ")
      # warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ")
      # warn ["Attributes:".magenta, "#{self.attributes}".cyan].join(" ")
      # warn ["Title: ".magenta, title.cyan, "style:", self.style].join(" ") if title
      # warn ["Content:".magenta, "#{self.content}".yellow].join(" ")
      # warn ["Style:".green, "#{self.style}".red].join(" ")
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

      report if $VERBOSE

      attr = self.attributes

      # Get title !- nil or make a dummy one
      title = self.attributes["title"]
      if title == nil
        title = "Dummy"
      end

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
      # warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      # warn "attributes: #{self.attributes}".cyan if $VERBOSE
      "\\begin\{verbatim\}\n#{self.content}\n\\end\{verbatim\}\n"
    end

    def example_process
      warn "example_process, title: #{self.title}".yellow
      warn "id: #{self.attributes['id']}".blue
      warn "role: #{self.attributes['role']}".blue
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
      if document.attributes['noteshare'] == 'yes'
        # warn "IXX: extracting image name".red if $VERBOSE
        image_rx = /image.*original\/(.*)\?/
        match_data = raw_image.match image_rx
        if match_data
          image = match_data[1]
          # warn "IXX: image name: #{image}".red if $VERBOSE
        else
          image = "undefined"
        end
      else
        image = raw_image
      end
      caption =   "\\caption\{#{self.attributes['title']}\}"
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
      "\\begin{#{figure_type}}#{position}\{#{ftext_width}\}\n\\includegraphics[width=#{width}]{#{image}}\n#{caption}\n#{align}\n\\end{#{figure_type}}\n"
    end

    def preamble_process
      "\\begin\{preamble\}\n#{self.content}\n\\end\{preamble\}\n"
    end


    def sidebar_process
      title = self.title
      attr = self.attributes
      id = attr['id']
      if id
        content = "\\hypertarget\{#{id}\}\{#{self.content}\}"
      else
        content = self.content
      end
      if title
        title  = $tex.macro 'bf', title
        $tex.env 'sidebar', "#{title}\\\\#{content}"
      else
        $tex.env 'sidebar', content
      end
    end

    def verse_process
      $tex.env 'alltt', self.content
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
      else
        # warn "This is Asciidoctor::Inline, tex_process.  I don't know how to do that (#{self.node_name})".yellow if $VERBOSE
        ""
      end
    end

    def inline_quoted_process
      # warn ["Node:".blue, "#{self.node_name}".cyan,  "type[#{self.type}], ".green + " text: #{self.text}"].join(" ") if $VERBOSE
      case self.type
        when :strong
          #"\\textbf\{#{self.text}\}"
          self.text
        when :emphasis
          "\\emph\{#{self.text}\}"
        when :asciimath
          #"\(#{LaTeX::TeXPostProcess.stem_substitutions self.text}\)"
          self.text
        when :monospaced
          "\{\\tt #{self.text}\}"
        when :superscript
          # warn "SUPER: #{self.attributes}"
          "$\{\}^{#{self.text}}$"
        when :subscript
          # warn "SUB: #{self.attributes}"
          "$\{\}_{#{self.text}}$"
        when :mark
          "\\colorbox\{yellow\}\{ #{self.text}\}"
        when :double
          "``#{self.text}''"
        when :single
          "`#{self.text}'"
        when :latexmath
          # "\(#{LaTeX::TeXPostProcess.stem_substitutions self.text}\)"
          self.text
        when :unquoted
          role = self.attributes["role"]
          # warn "  --  role = #{role}".yellow if $VERBOSE
          if role == "red"
            "\\rolered\{ #{self.text}\}"
          elsif role == "blue"
            "\\roleblue\{ #{self.text}\}"
          else
            # warn "This is inline_quoted_process.  I don't understand role = #{role}" if $VERBOSE
          end
        else
          "\\unknown\\{#{self.text}\\}"
      end
    end

    def inline_anchor_process

      # warn ["Node:".blue, "#{self.node_name}".magenta,  "type[#{self.type}], ".green + " text: #{self.text} target: #{self.target}".cyan].join(" ") if $VERBOSE

      refid = self.attributes['refid']
      refs = self.parent.document.references[:ids]
      # FIXME: the next line is HACKISH (and it crashes the app when refs[refid]) is nil)
      # FIXME: and with the fix for nil results is even more hackish
      # if refs[refid]
      if refs[refid]
        reftext = refs[refid].gsub('.', '')
        m = reftext.match /(\d*)/
        if m[1] == reftext
          reftext = "(#{reftext})"
        end
      else
        reftext = ""
      end
      case self.type
        when :link
          $tex.macro 'href', self.target, self.text
        when :ref
          $tex.macro 'label', self.text.gsub(/\[(.*?)\]/, "\\1")
        when :xref
          $tex.macro 'hyperlink', refid, reftext
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
          row_array << cell.content[0]
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
    # inside the TeX enveronment.  Strings
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

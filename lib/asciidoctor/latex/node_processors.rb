require 'asciidoctor'
require 'asciidoctor/latex/core_ext/colored_string'


module Asciidoctor
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
      warn "Node: #{self.class}".blue if $VERBOSE

      doc = ''

      # warn "document.attributes['header'] = #{document.attributes['header']}".magenta if $VERBOSE

      unless embedded? or document.attributes['header']=='no'
        doc << "%% Preamble %%\n"
        if File.exist? 'preamble.tex'
          preamble = IO.read('preamble.tex')
          warn "preamble: #{preamble.length} chars".yellow
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
          warn "macros: #{macros.length} chars".yellow
          doc << macros
        else
          warn "Could not find file macros.tex".yellow
        end
        if File.exist?('myEnvironments.tex')
          warn "I will take input from myEnvironments.tex".blue
          doc << "\\input myEnvironments.tex\n"
        else
          warn "I will take input from newEnvironments.tex".blue
          doc << "\\input newEnvironments.tex\n"
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
        warn "Writing environment definitions to file: newEnvironments.tex" if $VERBOSE
        definitions = ""

        $latex_environment_names.uniq.each do |name|
          warn name if $VERBOSE
          definitions << "\\newtheorem\{#{name}\}\{#{name.capitalize}\}" << "\n"
        end

        File.open('newEnvironments.tex', 'w') { |f| f.write(definitions) }

        # Output
        doc << "\n\\end{document}\n"
      end

      doc << "\n"
    end
  end

  # Write TeX for each of five levels of Ascidoc section,
  # .e.g. \section{Introduction} for == Introduction
  class Section

    def tex_process
      warn ["Node:".blue, "section[#{self.level}]:".cyan, "#{self.title}"].join(" ") if $VERBOSE
      doctype = self.document.doctype

      tags = { 'article' => [ 'part',  'section', 'subsection', 'subsubsection', 'paragraph' ],
               'book' => [ 'part', 'chapter', 'section', 'subsection', 'subsubsection', 'paragraph' ] }

      tagname = tags[doctype][self.level]
      tagsuffix = self.numbered ? '' : '*'

      "\\#{tagname}#{tagsuffix}\{#{self.title}\}\n\n#{self.content}\n\n"
    end
  end


  # Write TeX \itemize or \enumerate lists
  # for ulist and olist.  Recurses for
  # nested lists.
  class List

    def tex_process
      warn ["Node:".blue, "#{self.node_name}[#{self.level}]".cyan, "#{self.content.count} items"].join(" ") if $VERBOSE
      case self.node_name
      when 'dlist'
        dlist_process
      when 'ulist'
        ulist_process
      when 'olist'
        olist_process
      else
        warn "This Asciidoctor::List, tex_process.  I don't know how to do that (#{self.node_name})" if $VERBOSE
      end
    end

    def dlist_process
      list = "\\begin{description}\n\n"
      self.items.each do |terms, dd|
        list << "\\item["
        [*terms].each do |dt|
        warn ["  --  item: ".blue, "#{dt.text}"].join(" ") if $VERBOSE
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
        warn ["  --  item: ".blue, "#{item.text.split("\n").first}"].join(" ") if $VERBOSE
        list << "\\item #{item.text}\n\n"
        list << item.content
      end
      list << "\\end{itemize}\n\n"
    end

    def olist_process
      list = "\\begin{enumerate}\n\n"
      self.content.each do |item|
        warn ["  --  item:  ".blue, "#{item.text.split("\n").first}"].join(" ") if $VERBOSE
        list << "\\item #{item.text}\n\n"
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
      warn ["Node:".blue , "#{self.blockname}".blue].join(" ") if $VERBOSE
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
      # when :table
        # self.table_process
      else
        warn "This is Asciidoctor::Block, tex_process.  I don't know how to do that (#{self.blockname})" if $VERBOSE if $VERBOSE
        ""
      end
    end

    def paragraph_process
      LaTeX::TeXPostProcess.make_substitutions(self.content) << "\n\n"
    end

    def stem_process
      warn ["Node:".blue, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      warn self.content.cyan if $VERBOSE
      environment = LaTeX::TeXBlock.environment_type self.content
      if LaTeX::TeXBlock::INNER_TYPES.include? environment
        out = "\\\[\n#{LaTeX::TeXPostProcess.stem_substitutions self.content}\n\\\]\n"
        warn out.yellow if $VERBOSE
        out
      else
        self.content
      end
    end

    def admonition_process
      warn ["Node:".blue, "#{self.blockname}".cyan, "#{self.style}:".magenta, "#{self.lines[0]}"].join(" ") if $VERBOSE
      "\\admonition\{#{self.style}\}\{#{self.content}\}\n"
    end

    def page_break_process
      warn ["Node:".blue, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      "\n\\vfill\\eject\n"
    end

    def literal_process
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      "\\begin\{verbatim\}\n#{self.content}\n\\end\{verbatim\}\n"
    end

    def pass_process
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      self.content
    end

    def quote_process
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      if self.attr? 'attribution'
        attribution = self.attr 'attribution'
        citetitle = (self.attr? 'citetitle') ? (self.attr 'citetitle') : nil

        "\\begin\{aquote\}{#{attribution}#{citetitle ? ' - ' + citetitle : ''}}\n#{self.content}\\end\{aquote\}\n"
      else
        "\\begin\{quote\}\n#{self.content}\\end\{quote\}\n"
      end
    end



    def environment_process

      warn "begin environment_process, ".blue + "title = #{self.title}".yellow if $VERBOSE
      warn "role = #{self.attributes["role"]}" if $VERBOSE

      env = self.attributes["role"]

      # record any environments encountered but not built=in
      if !STANDARD_ENVIRONMENT_NAMES.include? env and !$latex_environment_names.include? env
      # if  !($latex_environment_names.include? env)
        warn "env added: [#{env}]".blue if $VERBOSE
        $latex_environment_names << env
      end

      if self.id
        label = "\n\\label\{#{self.id}\}"
      else
        label = ""
      end

      if env == 'listing'
        output = "\\begin\{#{env}\}#{label}\\begin{verbatim}\n\n#{self.content}\\end{verbatim}\n\\end\{#{env}\}\n"
      elsif env == 'equationalign'
        output = "\\begin\{equation\}#{label}\n\\begin\{split\}\n#{self.content}\n\\end\{split\}\n\\end\{equation\}\n"
      elsif env == 'chem'
        output = "\\begin\{equation\}#{label}\n\\ce\{#{self.content}\}\n\\end\{equation\}\n"
      else
        output = "\\begin\{#{env}\}#{label}\n#{self.content}\n\\end\{#{env}\}\n"
      end



      output

    end

    def click_process

      warn "begin click_process".blue + "title = #{self.title}".yellow if $VERBOSE

      click = self.attributes["role"]
      # record any environments encounted but not built=in
      if !STANDARD_ENVIRONMENT_NAMES.include? click
        $latex_environment_names << click
      end

      if self.id == nil # No label
        output = "\\begin\{#{click}\}\n#{self.content}\n\\end\{#{click}\}\n"
      else
        output = "\\begin\{#{click}\}\n\\label\{#{self.id}\}\n#{self.content}\\end\{#{click}\}\n"
      end

      warn "end click_process\n".blue if $VERBOSE

      output

    end

    def report
      # Report on this node
      warn ["OPEN BLOCK:".magenta, "id: #{self.id}"].join(" ")
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ")
      warn ["Attributes:".magenta, "#{self.attributes}".cyan].join(" ")
      warn ["Title: ".magenta, title.cyan, "style:", self.style].join(" ") if title
      warn ["Content:".magenta, "#{self.content}".yellow].join(" ")
      warn ["Style:".green, "#{self.style}".red].join(" ")
      warn ["METHODS:".red, "#{self.methods}".yellow].join(" ")
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

      warn "attributes (open block): #{self.attributes}" if $VERBOSE

      # Get title !- nil or make a dummy one
      title = self.attributes["title"]
      if title == nil
        title = "Dummy"
      end




       # strip constructs like {counter:theorem} from the title
       title = title.gsub /\{.*?\}/, ""
       title = title.strip

      if attr['role'] == 'text-center'
        "\\begin\{center\}\n#{self.content}\\end\{center\}"
      else
        self.content
      end


    end

    def listing_process
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      warn "attributes: #{self.attributes}".cyan if $VERBOSE
      "\\begin\{verbatim\}\n#{self.content}\n\\end\{verbatim\}\n"
    end

    def example_process
      warn "exAmple_process".yellow
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      warn "attributes: #{self.attributes}".cyan if $VERBOSE
      # self.content_model = :verbatim
      warn "content: #{self.content}".cyan if $VERBOSE
      "\\begin\{verbatim\}\n#{self.content}\n\\end\{verbatim\}\n"
    end


    def floating_title_process
      warn ["Node:".blue, "section[#{self.level}]:".cyan, "#{self.title}"].join(" ") if $VERBOSE
      doctype = self.document.doctype

      tags = { 'article' => [ 'part',  'section', 'subsection', 'subsubsection', 'paragraph' ],
               'book' => [ 'part', 'chapter', 'section', 'subsection', 'subsubsection', 'paragraph' ] }

      tagname = tags[doctype][self.level]

      "\\#{tagname}*\{#{self.title}\}\n\n#{self.content}\n\n"
    end

    def image_process
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      warn "attributes: #{self.attributes}".cyan if $VERBOSE
      if self.attributes['width']
        width = "#{self.attributes['width'].to_f/100.0}truein"
      else
        width = '2.5truein'
      end
      image = self.attributes['target']
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
      "\\begin{#{figure_type}}#{position}\{#{ftext_width}\}\n\\includegraphics[width=#{width}]{#{image}}\n#{caption}\n#{align}\n\\end{#{figure_type}}\n"
    end

    def preamble_process
      "\\begin\{preamble\}\n#{self.content}\n\\end\{preamble\}\n"
    end


    def sidebar_process
      warn "sidebar_process".yellow if $VERBOSE
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      warn "attributes: #{self.attributes}".cyan if $VERBOSE
      "\\begin\{sidebar\}\n#{self.content}\n\\end\{sidebar\}\n"
    end

    def verse_process
      warn "verse_process".yellow if $VERBOSE
      warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
      warn "attributes: #{self.attributes}".cyan if $VERBOSE
      "\\begin\{alltt\}\n#{self.content}\n\\end\{alltt\}\n"
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
      else
        warn "This is Asciidoctor::Inline, tex_process.  I don't know how to do that (#{self.node_name})".yellow if $VERBOSE
        ""
      end
    end

    def inline_quoted_process
      warn ["Node:".blue, "#{self.node_name}".cyan,  "type[#{self.type}], ".green + " text: #{self.text}"].join(" ") if $VERBOSE
      case self.type
      when :strong
        #"\\textbf\{#{self.text}\}"
        self.text
      when :emphasis
        "\\emph\{#{self.text}\}"
      when :asciimath
        "\$#{LaTeX::TeXPostProcess.stem_substitutions self.text}\$"
      when :monospaced
        "\{\\tt #{self.text}\}"
      when :unquoted
        role = self.attributes["role"]
        warn "  --  role = #{role}".yellow if $VERBOSE
        if role == "red"
          "\\rolered\{ #{self.text}\}"
        else
          warn "This is inline_quoted_process.  I don't understand role = #{role}" if $VERBOSE
        end
      else
        "\\unknown\\{#{self.text}\\}"
      end
    end

    def inline_anchor_process

      warn ["Node:".blue, "#{self.node_name}".magenta,  "type[#{self.type}], ".green + " text: #{self.text} target: #{self.target}".cyan].join(" ") if $VERBOSE

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
        "\\href\{#{self.target}\}\{#{self.text}\}"
      when :ref
        "\\label\{#{self.text.gsub(/\[(.*?)\]/, "\\1")}\}"
      when :xref
        #"\\ref\{#{self.target.gsub('#','')}\}"
        # warn "\\hyperlink\{#{refid}\}\{#{reftext}\}".yellow
        "\\hyperlink\{#{refid}\}\{#{reftext}\}"
      else
        warn "!!  : undefined inline anchor -----------".magenta if $VERBOSE
      end
    end

    def inline_break_process
      warn ["Node:".blue, "#{self.node_name}".cyan,  "type[#{self.type}], ".green + " text: #{self.text}"].join(" ") if $VERBOSE
      "#{self.text} \\\\"
    end

    def inline_footnote_process
      warn ["Node:".blue, "#{self.node_name}".cyan,  "type[#{self.type}], ".green + " text: #{self.text}"].join(" ") if $VERBOSE
      # warn self.content.yellow
      # warn self.style.magenta
      "\\footnote\{#{self.text}\}"
    end

  end

  class Table

    def tex_process
      # warn "This is Asciidoctor::Table, tex_process.  I don't know how to do that".yellow +  " (#{self.node_name})".magenta if $VERBOSE
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

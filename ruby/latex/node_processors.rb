require_relative 'colored_text'

class Asciidoctor::Document
  
  
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
    # warn "Attributes: #{self.attributes}".yellow
    # warn "#{self.methods}".magenta
    doc = "%% Preamble %%\n"
    doc << File.open("preamble.tex", 'r') { |f| f.read }
    doc << "%% Asciidoc TeX Macros %%\n"
    doc << File.open("asciidoc_tex_macros.tex", 'r') { |f| f.read }
    doc << "%% User Macros %%\n"
    doc << File.open("macros.tex", 'r') { |f| f.read }
    doc << "%% Front Matter %%"
    doc << "\n\n\\title\{#{self.doctitle}\}\n"
    doc << "\\author\{#{self.author}\}\n"
    doc << "\\date\{#{self.revdate}\}\n\n\n"
    doc << "%% Begin Document %%"
    doc << "\n\n\\begin\{document\}\n"
    doc << "\\maketitle\n"
    if self.attributes["toc"]
      doc << "\\tableofcontents\n"
    end
    doc << "%% Begin Document Text %%\n"
      
    processed_content = TeXBlock.process_environments self.content
    doc << processed_content
    # warn self.content
    
    doc << "\n\n\\end{document}\n\n" 
  end 
  
end


# Write TeX for each of five levels of Ascidoc section,
# .e.g. \section{Introction} for == Introduction
class Asciidoctor::Section
 
  def tex_process
    warn ["Node:".blue, "section[#{self.level}]:".cyan, "#{self.title}"].join(" ") if $VERBOSE
    case self.level
    when 1
       "\\section\{#{self.title}\}\n\n#{self.content}\n\n"
     when 2
       "\\subsection\{#{self.title}\}\n\n#{self.content}\n\n"
     when 3
       "\\subsubsection\{#{self.title}\}\n\n#{self.content}\n\n"
     when 4
       "\\paragraph\{#{self.title}\}\n\n#{self.content}\n\n"
     when 5
       "\\subparagraph\{#{self.title}\}\n\n#{self.content}\n\n"
     end  
  end
 
end


# Write TeX \itemize or \enumerate lists
# for ulist and olist.  Recurses for
# nested lists.
class Asciidoctor::List
  
  def tex_process
   warn ["Node:".blue, "#{self.node_name}[#{self.level}]".cyan, "#{self.content.count} items"].join(" ") if $VERBOSE
   case self.node_name
   when 'ulist'
     ulist_process
   when 'olist'
     olist_process
   else
     warn "This Asciidoctor::List, tex_process.  I don't know how to do that (#{self.node_name})" unless $VERBOSE.nil?
   end
  end 
   
  def ulist_process
    list = "\\begin{itemize}\n\n"
    self.content.each do |item|
      warn ["  --  item: ".blue, "#{item.text.abbreviate}"].join(" ") if $VERBOSE
      list << "\\item #{item.text}\n\n"
      list << item.content
    end
    list << "\\end{itemize}\n\n"  
  end
  
  def olist_process
    list = "\\begin{enumerate}\n\n"
    self.content.each do |item|
      warn ["  --  item:  ".blue, "#{item.text.abbreviate}"].join(" ") if $VERBOSE
      list << "\\item #{item.text}\n\n"
      list << item.content
    end
    list << "\\end{enumerate}\n\n"  
  end
  
end


# Proces block elements of varios kinds
class Asciidoctor::Block
  
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
    when :listing
      self.listing_process
    else
      warn "This is Asciidoctor::Block, tex_process.  I don't know how to do that (#{self.blockname})" unless $VERBOSE.nil?
      ""
    end  
  end 
  
  def paragraph_process
    self.content.tex_post_process << "\n\n"
  end
  
  def stem_process
    warn ["Node:".blue, "#{self.blockname}".cyan].join(" ") if $VERBOSE 
    warn self.content.cyan
    environment = TeXBlock.environment_type self.content
    if TeXBlock::INNER_TYPES.include? environment
      out = "\\\[\n#{self.content.stem_post_process}\n\\\]\n"
      warn out.yellow
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
    "\\begin\{quote\}\n#{self.content}\n\\end\{quote\}\n"
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
     warn ["OPEN BLOCK:".magenta, "id: #{self.id}"].join(" ") if $VERBOSE
     warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
     #warn ["Attributes:".magenta, "#{self.attributes}".cyan].join(" ") if $VERBOSE
     title = self.attributes["title"]
     title = title.gsub /\{.*?\}/, ""
     title = title.strip
     warn ["Title: ".magenta, title.cyan].join(" ")
     warn ["Content:".magenta, "#{self.content}".yellow].join(" ") if $VERBOSE
     "\\begin\{#{title}\}\n\\label\{#{self.id}\}\n#{self.content}\n\\end\{#{title}\}\n"
         
  end
  
  def listing_process
    warn ["Node:".magenta, "#{self.blockname}".cyan].join(" ") if $VERBOSE
    warn self.content.yellow
    "\\begin\{verbatim\}\n#{self.content}\n\\end\{verbatim\}\n"
  end
 
end


# Process inline elements
class Asciidoctor::Inline
  
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
      warn "This is Asciidoctor::Inline, tex_process.  I don't know how to do that (#{self.node_name})" unless $VERBOSE.nil?
      ""
    end  
  end 
  
  def inline_quoted_process
    warn ["Node:".blue, "#{self.node_name}".cyan,  "type[#{self.type}], ".green + " text: #{self.text}"].join(" ") if $VERBOSE 
    case self.type
    when :strong
      "\\textbf\{#{self.text}\}"
    when :emphasis
      "\\emph\{#{self.text}\}"
    when :asciimath
      "\$#{self.text.stem_post_process}\$"
    when :monospaced
      "\{\\tt #{self.text}\}"
    when :unquoted
      role = self.attributes["role"]
      warn "  --  role = #{role}".yellow if $VERBOSE
      if role == "red"
        "\\rolered\{ #{self.text}\}"
      else
        warn "This is inline_quoted_process.  I don't understand role = #{role}" unless $VERBOSE.nil?
      end
    else
      "\\unknown\\{#{self.text}\\}"
    end 
  end
  
  def inline_anchor_process
    warn ["Node:".blue, "#{self.node_name}".magenta,  "type[#{self.type}], ".green + " text: #{self.text} target: #{self.target}".cyan].join(" ") if $VERBOSE
    # warn "self.class = #{class}".yellow if $VERBOSE
    case self.type
    when :link
      "\\href\{#{self.target}\}\{#{self.text}\}"
    when :ref
      "\\label\{#{self.text.gsub(/\[(.*?)\]/, "\\1")}\}"
    when :xref
      "\\ref\{#{self.target.gsub('#','')}\}"
    else
      warn "!!  : undefined inline anchor -----------".magenta unless $VERBOSE.nil?
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

class String
  
  def tex_post_process
    TexPostProcess.make_substitutions self
  end
  
  def stem_post_process
    TexPostProcess.stem_substitutions self
  end
  
end


# TeXPostProcess cleans up undesired transformations
# inside the TeX enveronment.  Strings
# &ampp;, &gt;, &lt; are mapped back to 
# &, >, < and \\ is conserved.
module TexPostProcess
  
  def TexPostProcess.getInline str
	  rx_tex_inline = /\$(.*?)\$/
	  matches = str.scan rx_tex_inline
  end
  
  def TexPostProcess.getBlock str
	  rx_tex_block = /\\\[(.*?)\\\]/m
	  matches = str.scan rx_tex_block
  end
  
  def TexPostProcess.make_substitutions1 str
	  str = str.gsub("&amp;", "&")
    str = str.gsub("&gt;", ">")
    str = str.gsub("&lt;", "<")	  
  end
  
  def TexPostProcess.make_substitutions_in_matches matches, str   
	  matches.each do |m|
      m_str = m[0]
      m_transformed = TexPostProcess.make_substitutions1 m_str
      str = str.gsub(m_str,m_transformed)
    end
    str
  end
  
  # (1) & (2) are needed together to protect \\
  # inside of matrices, etc.
  def TexPostProcess.make_substitutions str
    str = str.gsub('\\\\', '@@')   # (1)
	  matches = TexPostProcess.getInline str
    if matches.count > 0
      str = TexPostProcess.make_substitutions_in_matches matches, str
    end
	  matches = TexPostProcess.getBlock str
    if matches.count > 0
      str = TexPostProcess.make_substitutions_in_matches matches, str
    end 
    str = str.tr('@','\\')         # (2)
    str
  end
  
  def TexPostProcess.stem_substitutions str
    str = str.gsub('\\\\', '@@')   # (1)
	  str = TexPostProcess.make_substitutions1 str
    str = str.tr('@','\\')         # (2)
    str
  end
  
  
end



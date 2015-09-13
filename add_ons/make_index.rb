class TextIndex

  attr_reader :text, :lines, :term_array, :index_map, :index_array, :index

  # Construct an array of lines
  # by reading a string or a file:
  # foo = TextIndex.new(string: 'ho ho ho')
  # foo = TextIndex.new(file: 'final_word.adoc')
  def initialize(hash)
    @lines = hash[:string].split("\n") if hash[:string]
    @lines = IO.readlines(hash[:file]) if hash[:file]
  end

  # locate the occurrences of terms marked
  # for indexing and return them as an array
  def self.scan_string(str)
    regex = /\(\((.*?)\)\)/
    str.scan(regex).flatten
  end

  # Return the terms to be index by
  # scanning the entire @lines array
  def scan
    regex = /\(\((.*?)\)\)/
    output = []
    @lines.each do |line|
      term_array = line.scan(regex)
      output << term_array
    end
    @term_array = output.flatten
  end

  # Build a hash, the @index_map which maps an index term to an
  # array of positions in the text.  Positions
  # range from 0 to (number of terms) - 1
  # Thus if the text contains the terms
  # 'foo', 'bar', and 'foo' in thar order, then
  #
  #   @index_map = { 'foo': [0, 2], 'bar': [1]}
  #
  # After the @index_map is contructed, it is used
  # to build @index_array -- the corresponding
  # array which is case-insenstive sorted on the
  # index terms.  Thus
  #
  #   @index_array = [ ['bar', [1]], ['foo', [0, 2]] ]
  #
  # @index_map is used in transforming the input
  # text, whereas @index_array is used to construct
  # the index
  #
  def make_index_map
    dict = {}
    @term_array.each_with_index do |element, index|
      if dict[element]
        dict[element] = dict[element] << index
      else
        dict[element] = [index]
      end
    end
    @index_map = dict
    @index_array = @index_map.to_a.sort{ |a,b| a[0].downcase <=> b[0].downcase }
  end

  # Map in index term to an inline_macro
  # representing its location in the index.
  # @index_map is used for this.  In the
  # example, the first time "transformed_term"
  # is applied to 'foo' the result is
  #
  #     "index_term::[foo, 0]".
  #
  # The second
  # time it is
  #
  #     "index_term::[foo, 2]"
  #
  # Asciidoctor converter, using the
  # HTML backend for the Asciidoctor-LaTeX
  # extension, transforms these to
  #
  #      "<span class='index_term' id='index_term_0'>foo</a>"
  #
  # etc.  These elements will be the targets of links
  # constructed in the index.
  def transformed_term(term)
    value = @index_map[term].dup
    if  value
      k = value.shift
      @index_map[term] = value
      "index_term::[#{term}, #{k}]"
    end
  end


  # Apply transform_term to each index term in the given line
  def transform_line(line)
    terms = TextIndex.scan_string(line)
    if terms
      terms.each do |term|
        line = line.gsub("((#{term}))", transformed_term(term))
      end
    end
    line
  end

  # replace the array of lines by an array in which
  # each term ((foo)) has been replaced by an element
  # of the form
  #
  #      index_term::[foo, k]
  #
  # where k is the position of foo in the text
  def transform_lines(outfile)
    file = File.open(outfile, 'w')
    @lines.each do |line|
      file.puts transform_line(line)
    end
    file.close
  end


  # Map each pair like ['bar', [1]] or
  # ['foo', [0,2]] to the corresponding
  # asciidoc reference for the index.
  # In the case at hand these are
  #
  #    <<index_term_1, bar>>
  #
  # and
  #
  #    <<index_term_0, foo>>, <<index_term_2, 2>>
  #
  # In the case of index terms that appear n > 1
  # times, the elements beyond the first are labeled
  # 2, 3, ..., n.  We should loook for a better
  # solution in the pageless environment of the web.
  #
  def index_pair_to_index_item(pair)
    reference = pair[0]
    indices = pair[1].dup
    index = indices.shift

    n = indices.count - 1
    count = 2
    out = ["<<index_term_#{index}, #{reference}>>"]
    if indices
      indices.each do |index|
        out <<  "<<index_term_#{index}, #{count}>>"
      end
    end
    out.join(', ') + " +\n"
  end


  # Construct the Asciidoc version of the index
  # by applying 'index_pair_to_index_item' to
  # each elemnet and accumulating the result
  # in the string 'output'
  def make_index
    output = ''
    @index_array.each do |index_pair|
      output << index_pair_to_index_item(index_pair)
    end
    @index = output
  end


  # Put it all together: write the transformed
  # Asciidoc file to outfile, along with the index.
  # The output is now ready to be processed by Asciidoctor.
  def preprocess(outfile)
    scan
    make_index_map
    make_index
    transform_lines(outfile)

    file = File.open(outfile, 'a')
    file.puts "\n\n== Index\n\n"
    file.puts index
    file.close
  end

end






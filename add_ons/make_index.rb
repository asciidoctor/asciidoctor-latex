class TextIndex

  attr_reader :text, :lines, :term_array, :index_map, :index_array, :index


  def initialize(input, option= nil)
    if option == nil
      @text = input
      @lines =  @text.split("\n")
    elsif option == :file
      @lines = IO.readlines input
    end
  end

  def self.scan_string(str)
    regex = /\(\((.*?)\)\)/
    str.scan(regex).flatten
  end

  def scan
    regex = /\(\((.*?)\)\)/
    output = []
    @lines.each do |line|
      term_array = line.scan(regex)
      output << term_array
    end
    @term_array = output.flatten
  end

  # Build a Hash which maps an index term to any
  # array of positions in the text
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

  def transformed_term(term)
    value = @index_map[term].dup
    if  value
      k = value.shift
      @index_map[term] = value
      "index_term::[#{term}, #{k}]"
    end
  end

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

  def make_index
    index_table = @index_map.to_a.sort{ |a,b| a[0].downcase <=> b[0].downcase }
    output = ''
    index_table.each do |index_pair|
      output << index_pair_to_index_item(index_pair)
    end
    @index = output
  end

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

def message
  out = "\nUsage: 'ruby make_index.rb foo.adoc'\n"
  out << "Purpose: add index to foo.adoc\n"
  out << "Output is in file foo-index.adoc\n\n"
end

def make_index
  if ARGV.count == 0
    puts message
    return
  end
  input_file = ARGV[0]
  ti = TextIndex.new input_file, :file
  basename = File.basename(input_file, '.adoc')
  output_file = "#{basename}-index.adoc"
  ti.preprocess(output_file)
end


make_index

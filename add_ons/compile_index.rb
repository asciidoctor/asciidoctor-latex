require_relative 'make_index'

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
  ti = TextIndex.new(file: input_file)
  basename = File.basename(input_file, '.adoc')
  output_file = "#{basename}-indexed.adoc"
  ti.preprocess(output_file)
  `asciidoctor-latex -b html #{output_file}`
end

make_index

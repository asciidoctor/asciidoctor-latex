require 'spec_helper'

describe TextIndex do



  before :each do

    @text = <<EOF
This is a test of ((Foo)).
That is to say, we went to the ((bar)).
However, ((Foo)) was nowhere to be found!
EOF



  end

  it 'breaks the text into an array of lines', :lines do

    ti = TextIndex.new(@text)
    ti.get_lines
    expect(ti.lines.count).to eq(3)

  end

  it 'scans the array lines, producing an array of index terms', :scan  do

    ti = TextIndex.new(@text)
    ti.scan
    expect(ti.term_array).to eq(["Foo", "bar", "Foo"])


  end

  it 'scans a string, producing and array of its terms', :scan_string do
    terms = TextIndex.scan_string('This is a test of ((Foo)). Afterwards we will go to the ((bar)).')
    expect(terms).to eq(["Foo", "bar"])
  end

  it 'produces a list of index terms from a piece of text' , :index_map do
    ti = TextIndex.new(@text)
    ti.scan
    ti.make_index_map
    expect(ti.index_map).to be_instance_of(Hash)
    expect(ti.index_map["Foo"]).to eq([0,2])
    expect(ti.index_map["bar"]).to eq([1])
  end

  it 'transforms a string, replacing terms with the corresponding asciidoc element', :transform_line do
    input = 'This is a test of ((Foo)). Afterwards we will go to the ((bar)).'
    ti = TextIndex.new(input)
    ti.scan
    ti.make_index_map
    output = ti.transform_line(input)
    expected_output = 'This is a test of index_term::[Foo, 0].'
    expected_output << ' Afterwards we will go to the index_term::[bar, 1].'
    expect(output).to eq(expected_output)
  end


  it 'transforms an array of lines, writing the output to a file', :transform_lines do
    ti = TextIndex.new(@text)
    ti.scan
    ti.make_index_map
    ti.transform_lines('out.adoc')
    output = File.read('out.adoc')
    expected_output = <<EOF
This is a test of index_term::[Foo, 0].
That is to say, we went to the index_term::[bar, 1].
However, index_term::[Foo, 2] was nowhere to be found!
EOF
    expect(output).to eq(expected_output)
  end

  it 'creates the data structure for the index', :index_array  do
    ti = TextIndex.new(@text)
    ti.scan
    ti.make_index_map
    expected_index_array  = [['bar', [1]], ['Foo', [0,2]]]
    expect(ti.index_array).to eq(expected_index_array)

  end

  it 'creates an Asciidoc version of the index', :ad_version do
    ti = TextIndex.new(@text)
    ti.scan
    ti.make_index_map
    d { ti.index_map ; ti.index_array}
    ti.make_index
    d { ti.index }
    expected_index_text = "<<index_item_1, bar>> +\n<<index_item_0, Foo>>, <<index_item_2, 2>> +\n"
    expect(ti.index).to eq(expected_index_text)
  end

  it 'transforms the marked index terms and appends an index to the generated asciidoc file', :preprocess do
    ti = TextIndex.new(@text)
    ti.preprocess('out.adoc')
    output = File.read('out.adoc')
    expected_output = "This is a test of index_term::[Foo, 0].\nThat is to say, we went to the index_term::[bar, 1].\nHowever, index_term::[Foo, 2] was nowhere to be found!\n\n\n== Index\n\n<<index_item_1, bar>> +\n<<index_item_0, Foo>>, <<index_item_2, 2>> +\n"
    expect(output).to eq(expected_output)
  end

end

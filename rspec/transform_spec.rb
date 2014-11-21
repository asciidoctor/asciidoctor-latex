require 'asciidoctor'
require 'asciidoctor-latex'
require_relative 'transform'
require_relative '../lib/asciidoctor-latex/colored_text'
include Transform

VERBOSE = true

def compare_transform input, expected_output, transfomer
  
  warn ' ' if VERBOSE
  warn input.blue if VERBOSE
  warn expected_output.cyan if VERBOSE
  output = Transform.map_string input, transfomer
  warn output.blue if VERBOSE
  warn ' ' if VERBOSE
  expect(output).to eq expected_output
  
end


describe Transform do
  
  before :each do
    
  end
  
  it 'reads the contents of a file into a string' do
  
    contents = Transform.read_string 'data/foo'
    expect(contents.chomp).to eq 'foo.bar'
    
  end
  
  it 'implements the identity transform on strings' do
    
    input = 'foo'
    output = Transform.map_string input, $identity
    expect(input).to eq output
    
  end
  
  it 'maps dollar-delimted strings to escapa-paren delimited strings' do
    
    input = 'ha ha ha $a^2 = 1$ ho ho ho'
    expected_output = 'ha ha ha \\(a^2 = 1\\) ho ho ho'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'maps dollar-delimted strings to latexmath-delimited strings' do
    
    input = 'ha ha ha $a^2 = 1$ ho ho ho'
    expected_output = 'ha ha ha latexmath:[a^2 = 1] ho ho ho'
    compare_transform input, expected_output, $fixmath2
    
  end
  
  it 'handles the edge case of a dollar sign at the beginning of the line' do
    
    input = '$a^2 = 1$ ho ho ho'
    expected_output = '\\(a^2 = 1\\) ho ho ho'
    compare_transform input, expected_output, $fixmath    
    
  end
  
  it 'handles the edge case of a dollar sign at the beginning of the line in latexmath' do
    
    input = '$a^2 = 1$ ho ho ho'
    expected_output = 'latexmath:[a^2 = 1] ho ho ho'
    compare_transform input, expected_output, $fixmath2    
    
  end
  
  it 'handles the edge case of a dollar sign at the end of the line'  do
    
    input = 'ha ha ha $a^2 = 1$'
    expected_output = 'ha ha ha \\(a^2 = 1\\)'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'handles the edge case of a dollar sign at the end of the line wth latexmath'  do
    
    input = 'ha ha ha $a^2 = 1$'
    expected_output = 'ha ha ha latexmath:[a^2 = 1]'
    compare_transform input, expected_output, $fixmath2
    
  end
  
  it 'handles the edge case of a dollar sign at the beginnng and end of the line'  do
    
    input = 'a^2 = 1$'
    expected_output = '\\(a^2 = 1\\)'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'handles the edge case of a dollar sign at the beginnng and end of the line plus a little  space in mode 2'  do
    
    input = ' a^2 = 1 $'
    expected_output = ' latexmath:[a^2 = 1] '
    compare_transform input, expected_output, $fixmath2
    
  end
  
  it 'handles the edge case of a dollar sign at the beginnng and end of the line in mode 2'  do
    
    input = 'a^2 = 1$'
    expected_output = 'latexmath:[a^2 = 1]'
    compare_transform input, expected_output, $fixmath2
    
  end
 
  
  it 'reads strings from files' do
    
    input = Transform.read_string 'data/lorem'
    expect(input.length).to be > 0
    
  end
  
  it 'implements the identity transform on files' do
    
    Transform.map_file 'data/lorem', 'data/tmp', $identity
    original_content = Transform.read_string 'data/lorem'
    transformed_content = Transform.read_string 'data/tmp'
    expect(transformed_content).to eq original_content
    
  end 
  
=begin  
  it 'applies the fixmath transform to files to files' do
    
    Transform.map_file 'data/tex2', 'data/tmp', $fixmath
    
    original_content = Transform.read_string 'data/tex2'
    transformed_content = Transform.read_string 'data/tmp'
    expected_content = Transform.read_string 'data/tex2.expect'
    
    warn ('|||'+original_content+'|||').blue if VERBOSE
    warn ('|||'+transformed_content+'|||').cyan if VERBOSE
    warn ('|||'+expected_content+'|||').blue if VERBOSE
    expect(transformed_content).to eq expected_content     
  end 
=end    
  
  
end
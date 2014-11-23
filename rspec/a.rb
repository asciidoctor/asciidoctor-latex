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
  
  it 'reads the contents of a file into a string (A1)' do
  
    contents = Transform.read_string 'data/foo'
    expect(contents.chomp).to eq 'foo.bar'
    
  end
  
  it 'implements the identity transform on strings (A2)' do
    
    input = 'foo'
    output = Transform.map_string input, $identity
    expect(input).to eq output
    
  end
  
  it 'maps dollar-delimted strings to escapa-paren delimited strings (A3)' do
    
    input = 'ha ha ha $a^2 = 1$ ho ho ho'
    expected_output = 'ha ha ha \\(a^2 = 1\\) ho ho ho'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'maps dollar-delimted strings to latexmath-delimited strings' do
    
    input = 'ha ha ha $a^2 = 1$ ho ho ho'
    expected_output = 'ha ha ha latexmath:[a^2 = 1] ho ho ho'
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
  

  
end
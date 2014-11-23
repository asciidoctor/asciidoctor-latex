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
  

  
  it 'handles the edge case of a dollar sign at the beginning of the line (A)' do
    
    input = '$a^2 = 1$ ho ho ho'
    expected_output = '\\(a^2 = 1\\) ho ho ho'
    compare_transform input, expected_output, $fixmath    
    
  end
  
  it 'handles the edge case of a dollar sign at the beginning of the line in latexmath (B)' do
    
    input = '$a^2 = 1$ ho ho ho'
    expected_output = 'latexmath:[a^2 = 1] ho ho ho'
    compare_transform input, expected_output, $fixmath2    
    
  end
  
  it 'handles the edge case of a dollar sign at the end of the line (C)'   do
    
    input = 'ha ha ha $a^2 = 1$'
    expected_output = 'ha ha ha \\(a^2 = 1\\)'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'handles the edge case of a dollar sign at the end of the line wth latexmath (D)'  do
    
    input = 'ha ha ha $a^2 = 1$'
    expected_output = 'ha ha ha latexmath:[a^2 = 1]'
    compare_transform input, expected_output, $fixmath2
    
  end
  
  it 'handles the edge case of a dollar sign at the beginnng and end of the line (E)'  do
    
    input = '$a^2 = 1$'
    expected_output = '\\(a^2 = 1\\)'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'handles the edge case of a dollar sign at the beginnng and end of the line plus a little  space in mode 2 (F)'  do
    
    input = ' $a^2 = 1 $'
    expected_output = ' latexmath:[a^2 = 1]'
    compare_transform input, expected_output, $fixmath2
    
  end
  
  it 'handles the edge case of a dollar sign at the beginnng and end of the line in mode 2 (G)'  do
    
    input = '$a^2 = 1$'
    expected_output = 'latexmath:[a^2 = 1]'
    compare_transform input, expected_output, $fixmath2
    
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
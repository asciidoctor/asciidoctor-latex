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
  
  
  it 'maps the text "$x$" correctly (A)' do
    
    input = '$x$'
    expected_output = '\(x\)'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'maps the text "$x$?" correctly (B)' do
    
    input = '$x$?'
    expected_output = '\(x\)?'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'maps the text "$x$-axis" correctly (C)' do
    
    input = '$x$?-axis'
    expected_output = '\(x\)-axis'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'maps the text "$Fe^{3+}$" correctly (D)' do
    
    input = '$Fe^{3+}$'
    expected_output = '\(Fe^{3+}\)'
    compare_transform input, expected_output, $fixmath
    
  end
  
  it 'maps the text "$Cr^{+2}$ $Fe^{3+}$" correctly (E)' do
    
    input = '$Cr^{+2}$ $Fe^{3+}$'
    expected_output = '\(Cr^{+2}\) \(Fe^{3+}\)'
    compare_transform input, expected_output, $fixmath
    
  end
  
  
end
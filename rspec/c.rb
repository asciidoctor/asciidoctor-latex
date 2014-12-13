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

  it 'maps the text "$\pi:U^+ \map U$" correctly (E)' do

    input = '$\pi:U^+ \map U$'
    expected_output = '\(\pi:U^+ \map U\)'
    compare_transform input, expected_output, $fixmath

  end

  it 'maps the text "$\pi^{-1}(U) = U^+ \cup U^-" correctly (E)' do

    input = '$\pi^{-1}(U) = U^+ \cup U^-$'
    expected_output = '\(\pi^{-1}(U) = U^+ \cup U^-\)'
    compare_transform input, expected_output, $fixmath

  end

  it 'maps the text "Then $\pi^{-1}(U) = U^+ \cup U^-$ is the disjoint union of two\nopen sets and $\pi:U^+ \map U$ is a local coordinate." correctly (E)' do

    input = 'Then $\pi^{-1}(U) = U^+ \cup U^-$ is the disjoint union of two\nopen sets and $\pi:U^+ \map U$ is a local coordinate.'
    expected_output = 'Then \(\pi^{-1}(U) = U^+ \cup U^-\) is the disjoint union of two\nopen sets and \(\pi:U^+ \map U\) is a local coordinate.'
    compare_transform input, expected_output, $fixmath

  end

  it 'parses a complicated expression correctly (1)' do

    input = <<EOF
iLet $a$ be a point of the set $\\CC - B$  let $U$ be a neighborhood of $a$ in
that set.  Then $\pi^{-1}(U) = U^+ \\cup U^-$ is the disjoint union of two
open sets and $\pi:U^+ \map U$ is a local coordinate.
EOF

    expected_output = <<EOF
Let \(a\) be a point of the set \(\\CC - B\)  let \(U\) be a neighborhood of \(a\) in
that set.  Then \(pi^{-1}(U) = U^+ \\cup U^-\) is the disjoint union of two
open sets and \(\pi:U^+ \map U\)is a local coordinate.
EOF

  compare_transform input, expected_output, $fixmath

  end

  it 'maps the text "Call these $y_+$ and $y_-$." correctly (E)' do

    input = 'Call these $y_+$ and $y_-$.'
    expected_output = 'Call these \(y_+\) and \(y_-\).'
    compare_transform input, expected_output, $fixmath

  end


end

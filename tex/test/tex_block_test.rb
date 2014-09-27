
require '/Users/carlson/Dropbox/prog/git/asciidoctor-backends/tex/tex_block/'
include TeXBlock

require 'test/unit'

eq_string= "ho ho ho\n\\\[\n\\begin\{equation\}\na^2 = 1\n\\end\{equation\}\n\\\]\nha ha ha"
$eq_string2 = eq_string + "\n" + eq_string

arr_string = "ho ho ho\n\\\[\n\\begin\{array\}\na^2 = 1\n\\end\{array\}\n\\\]\nha ha ha"
$arr_string2 = arr_string + "\n" + arr_string

$eq_string2_processed = "ho ho ho\n\n\\begin{equation}\na^2 = 1\n\\end{equation}\n\nha ha ha\nho ho ho\n\n\\begin{equation}\na^2 = 1\n\\end{equation}\n\nha ha ha"
$arr_string2_processed = "ho ho ho\n\\[\n\\begin{array}\na^2 = 1\n\\end{array}\n\\]\nha ha ha\nho ho ho\n\\[\n\\begin{array}\na^2 = 1\n\\end{array}\n\\]\nha ha ha" 

class TestTeXBlock  < Test::Unit::TestCase
 

  def test_eq_block
    $eq_string2_processed = TeXBlock.process_environments $eq_string2
    assert_equal($eq_string2, $eq_string2_processed, "The escaped-bracket delimiters should be stripped off")
  end
  
  def test_eq_block 
    $arr_string2_processed = TeXBlock.process_environments $arr_string2
    assert_equal($arr_string2, $arr_string2_processed, "The escaped-bracket delimiters should not be stripped off")
  end
 
  
end
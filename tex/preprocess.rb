# For trying things out
# Call the input file foo.in
# Then execute
# 
#   $ ruby preprocess foo
#
# Currently output is directed to the
# console.  Uncomment the last line
# to direct output to foo.out

require '/Users/carlson/Dropbox/prog/git/asciidoctor-backends/tex/tex_block/'
include TeXBlock


base_name = ARGV[0]
input_file = base_name + ".in"
output_file = base_name + "out"

input = File.open(input_file, 'r') { |f| f.read }

puts "input:"
puts "-----------------"
puts input
puts "-----------------\n\n"

output = TeXBlock.process_environments input 

puts "output:"
puts "-----------------"
puts output
puts "-----------------\n\n"

# File.open(output_file, 'w') {|f| f.write(output) }

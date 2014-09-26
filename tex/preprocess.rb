base_name = ARGV[0]
input_file = base_name + ".ad"
output_file = base_name + "2.ad"

input = File.open(input_file, 'r') { |f| f.read }

TEX_DOLLAR_RX = /(^|\s|\()\$(.*?)\$($|\s|\)|,|\.)/
TEX_DOLLAR_SUB = '\1stem:[\2]\3'

output = input.gsub TEX_DOLLAR_RX, TEX_DOLLAR_SUB

File.open(output_file, 'w') {|f| f.write(output) }

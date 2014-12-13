# TEX_DOLLAR_SUB = '\1latexmath:[\2]\3'

module Transform

  # Map $...$ to stem:[...]
  # Map $...$ to \( ... \)


  TEX_DOLLAR_RX = /(^|\s|\()\$(.*?)\$($|\s|\)|,|\.)/
  TEX_DOLLAR_SUB = '\1\\\(\2\\\)\3'
  TEX_DOLLAR_SUB2 = '\1latexmath:[\2]\3'

  $fixmath = lambda { |x| x.gsub TEX_DOLLAR_RX, TEX_DOLLAR_SUB }
  $fixmath2 = lambda { |x| x.gsub TEX_DOLLAR_RX, TEX_DOLLAR_SUB2 }

  $identity = lambda { |x| x }

  def Transform.read_string in_file
    return File.open(in_file, 'r') { |f| f.read }
  end

  def Transform.map_string str, transformer
    return transformer.call str
  end

  def Transform.map_file in_file, out_file, transform_string

    input = File.open(in_file, 'r') { |f| f.read }
    output = transform_string.call(input)
    File.open(out_file, 'w' ) { |f| f.write output }

  end



end

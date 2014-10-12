
class String
  
  def abbreviate
    self.split("\n")[0]
  end
  
  
  def blue
    "\e[1;34m#{self}\e[0m"
  end
  
  def green
    "\e[1;32m#{self}\e[0m"
  end

  def red
    "\e[1;31m#{self}\e[0m"
  end
  
  def yellow
    "\e[1;33m#{self}\e[0m"
  end
  
  def magenta
    "\e[1;35m#{self}\e[0m"
  end
  
  def cyan
    "\e[1;36m#{self}\e[0m"
  end
  
  def white
    "\e[1;37m#{self}\e[0m"
  end
  
  def black
    "\e[1;30m#{self}\e[0m"
  end

end


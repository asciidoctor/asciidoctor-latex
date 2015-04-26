

class String

  # This method allows one to compute
  # the strings that represent LaTeX
  # macro applicatins without descent
  # into a hell of backlslshes and braces,
  # especially when more than one macro
  # has to be applied.  For example,
  # instead of
  #
  #    content = "\\roleblue\{ #{content}\}"
  #
  # we say just
  #
  #    content = content.macro('roleblue')
  #
  # Here is an appication of three macros:
  #
  #    content.macro('roleblue').macro('foo').macro('bar')
  #
  #
  def macro(macro)
    "\\#{macro}\{#{self}\}"
  end

end

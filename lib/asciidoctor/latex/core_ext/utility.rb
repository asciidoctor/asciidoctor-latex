

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

  #   The 'apply_macros' method simplifies the
  #   chaining of a sequence of macro applications.
  #   For example, we could say
  #
  #   'yoda'.macro('baz').macro('bar').macro('foo')
  #
  #         => "\\foo{\\bar{\\baz{yoda}}}"
  #
  #   But it is simpler to say
  #
  #   'yoda'.apply_macros(['foo', 'bar', 'baz'])
  #
  #       => "\\foo{\\bar{\\baz{yoda}}}"
  #
  #   Because we reverse the argument list, the
  #   application order of the LaTeX macros
  #   matches the order in the argument list.

  def apply_macros(macro_list)
    val = self
    macro_list.reverse.each do |macro_name|
      val = val.macro(macro_name)
    end
    val
  end


end

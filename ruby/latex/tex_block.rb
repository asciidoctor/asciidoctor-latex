
# The purpose of the module TeXBlock is to
# transform structure of the form
# \[ ... \], either by passing them on unchanged
# or by stripping away the escaped braces.
#
# When ... is an environment such as
#
#     \begin{equation} ### \end{equation}
#
# the escaped braces must be stripped.
# All other cases, as far as I know now (not far:-),
# the braces remain.  
#
# For the moment the solution is to strip when
# the contents ... contain no string of the form
# \begin{XXX} except for the cases in which XXX is
# 
#    - array
#    - matrix
#
# I believe that the list of these keywords is small,
# whereas the number of other environments is large
# and essentially unbounded, since users can define
# their own environments.

module TeXBlock

  # Find blocks delmited by \[ ... \]
	def TeXBlock.get_tex_blocks str
	  rx_tex_block = /(\\\[)(.*?)(\\\])/m
	  matches = str.scan rx_tex_block
	end


  # Return the environment type of a tex block.
  # Thus, if str = \[\begin{foo} ho ho ho \end{foo}\],
  # the string "foo" is returned.
	def TeXBlock.environment_type str
	  rx_env_block = /\\begin\{(.*?)\}/
	  m = str.match rx_env_block 
    if m
      env_type = m[1]
    else
      env_type = 'none'
    end
    env_type
	end

  # Return the environment type from an
  # element of the array produced by 
  # get_tex_blocks -- each element is a 
  # three-element array with the tex block
  # as the middle element.
	def TeXBlock.environmemt_type_of_match m
	  environment_type m[1]
	end
  
  # Return the block as-is -- do not
  # strip delimiters.
	def TeXBlock.restore_match_data m
	  m.join()
	end

  # Return the block sans delimiters
	def TeXBlock.strip_match_data m
	  m[1]
	end
 
  # Transform the input string for a given block m
	def TeXBlock.process_tex_block m, str
	  block_type = TeXBlock.environmemt_type_of_match m
	  if INNER_TYPES.include? block_type
     output = str
    else
	   output = str.gsub TeXBlock.restore_match_data(m), TeXBlock.strip_match_data(m)
	  end
	  output
	end
   
  # Transform the input string by stripping or
  # passing each tex block as required
 	def TeXBlock.process_environments str
 	  tbs = get_tex_blocks str
 	  tbs.each do |tb|
 	    str = TeXBlock.process_tex_block tb, str
 	  end
 	  str
 	end
 
  # The list of "inner environments" whose enclosing
  # escaped braces are not to be stripped.
  INNER_TYPES = ["array", "matrix",  "none"]
 
end

#!/bin/sh

# file: test1.rb

# Test suite for LateX backend for Asciidoctor
# Run 
#
#   $ alias ru='sh test1.rb'
#
# for greater productivity and happiness

adx=/Users/carlson/.rbenv/shims/asciidoctor
laco=/Users/carlson/Dropbox/prog/git/asciidoctor-latex/lib/asciidoctor-latex/converter.rb
pre=/Users/carlson/Dropbox/prog/git/asciidoctor-latex/lib/asciidoctor-latex/tex_preprocessor.rb
post=/Users/carlson/Dropbox/prog/git/asciidoctor-latex/lib/asciidoctor-latex/ent_to_uni.rb

# browse='open -a /Applications/Safari.app'
browse='open -a /Applications/Chrome.app'
tex='xelatex'
viewpdf='open -a /Applications/Preview.app'


case $1 in
    -c)  echo "running all command line tests"
         $adx math.adoc
         $adx -r $laco -a stem=latexmath env.adoc
         $adx -r $laco -a stem=latexmath env.adoc -b latex
         $adx -r $laco -a stem=latexmath big.adoc
 		exit;;
	-r) echo "running all ruby API tests"
	    ruby test.rb big.adoc --tex
		cp blank.tex new_environments.tex
	    exit;;
	-a) echo "running all tests"
	    sh test1.sh -c
		sh test1.sh -r
		echo	
		exit;;
esac
	

case $2 in 
   -h)  echo $1.adoc ' --> html'
        $adx -r $laco $1.adoc
		tail -25 $1.html
		$browse $1.html
        exit;;
  -hm)  echo $1.adoc ' --> html, math mode: use preprocessor and -a stem=latexmath'
        $adx -r $laco -a stem=latexmath $1.adoc
 		$browse $1.html
		tail -25 $1.html
        exit;;
   -t)  echo $1.adoc '--> tex'
        $adx -r $laco -r $post $1.adoc -b latex
		cp blank.tex new_environments.tex 
		# ^^^ this is kludge - should not be necessary
		$tex $1.tex
		$tex $1.tex
		tail -25 $1.tex
		$viewpdf $1.pdf
        exit;;
esac

echo " "
echo "  Usage:"
echo " "
echo "  <file> means file without extension"
echo "  Thus use '<file> = foo' for 'foo.adoc', etc"
echo " "
echo "  ru <file> -h        -- html output"
echo "  ru <file> -hm       -- html output, math mode: use preprocessor and -a stem:latexmath"
echo "  ru <file> -t        -- tex output"
echo "  ru -c               -- run all command line tests"
echo "  ru -r               -- run all ruby API tests"
echo "  ru -a               -- run all tests"
echo " "
echo "  Some test files:"
echo "  "
echo "  math.adoc, env.adoc, big.adoc"
echo



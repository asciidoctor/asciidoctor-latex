#!/bin/sh
# Usage:  sh run.sh sample1
# Note: no .ad extension above


asciidoctor -r ./tex-converter.rb -b latex $1.ad -o converted.tex

cat preamble >tmp.tex
cat macros >>tmp.tex
cat converted.tex >>tmp.tex
echo "\n\n\end{document}\n\n" >>tmp.tex

cp tmp.tex $1.tex


# clean up
# rm converted.tex
rm *.log
rm *.aux

# /usr/local/texlive/2011/bin/universal-darwin/pdflatex foo.tex
# pv foo.pdf


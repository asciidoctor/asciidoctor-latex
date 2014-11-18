# file: tests.sh
# Purpose: exercise the LaTeX converter
# Usage: $ sh tests.sh

# Edit the varaibleas adx and laco to conform to local setup
adx=/Users/carlson/.rbenv/shims/asciidoctor
laco=/Users/carlson/Dropbox/prog/git/asciidoctor-latex/lib/asciidoctor-latex/converter.rb

$adx math.adoc
$adx -r $laco -a stem=latexmath env.adoc
$adx -r $laco -a stem=latexmath env.adoc -b latex
$adx -r $laco -a stem=latexmath big.adoc
$adx -r $laco -a stem=latexmath big.adoc -b latex
# ruby test.rb big.adoc --tex


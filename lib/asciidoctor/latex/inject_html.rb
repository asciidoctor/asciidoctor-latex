

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/latex/core_ext/colored_string'

#
module Asciidoctor::LaTeX

  class InjectHTML < Asciidoctor::Extensions::Postprocessor

    def process document, output
      output = output.gsub('</head>', $click_insertion)
    end

  end

  $click_insertion = <<EOF

<style>
  .click .title { color: blue; }
  .openblock>.box>.content { margin-top:1em;margin-bottom: 1em;margin-left:3em;margin-right:4em; }
</style>


<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>

<script>

  $(document).ready(function(){
    $('.openblock.click').click( function()  { $(this).find('.content').slideToggle('200');
      $.reloadMathJax() }  )
    $('.openblock.click').find('.content').hide()
  });

  $(document).ready(function(){
    $('.listingblock.click').click( function()  { $(this).find('.content').slideToggle('200') }  )
    $('.listingblock.click').find('.content').hide()
  });


  $(document).ready(ready);
  $(document).on('page:load', ready);
</script>

</head>

EOF

end

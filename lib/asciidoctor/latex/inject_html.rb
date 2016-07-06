

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/latex/core_ext/colored_string'

#
module Asciidoctor::LaTeX

  class InjectHTML < Asciidoctor::Extensions::Postprocessor

    def process document, output
      output.sub('</head>', $click_insertion)
    end

  end

  $click_insertion = <<EOF

<style>
  .click .title { color: blue; }
  .click {margin-top: 0.5em; margin-bottom: 0.5em;}
  .openblock { margin-top: 1em; margin-bottom: 1em; }
  .openblock>.box>.content { margin-top:1em;margin-bottom: 1em;margin-left:3em;margin-right:4em; }
</style>


<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>

<script>



var ready2;

ready2 = function() {

    $(document).ready(function(){

        $('.openblock.click').click( function()  { $(this).find('.content').slideToggle('200'); } )
        $('.openblock.click').find('.content').hide()


        $('.listingblock.click').click( function()  { $(this).find('.content').slideToggle('200') }  )
        $('.listingblock.click').find('.content').hide()

    });

}




$(document).ready(ready2);
$(document).on('page:load', ready2);


</script>

</head>

EOF

end

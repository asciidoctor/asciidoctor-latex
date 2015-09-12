require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include ::Asciidoctor

Extensions.register do
  # A treeprocessor that increments each level-1 section number by the value of
  # the `sectnumoffset` attribute.
  #
  # In addition, if `subsectnumoffset` is defined and greater than zero,
  # the numbers of subsections in the first section encountered will
  # be incremented by the offset.
  #
  # The numbers of all subsections will be
  # incremented automatically since those values are calculated dynamically.
  #
  # Run using:
  #
  # asciidoctor -r ./lib/sectnumoffset-treeprocessor.rb -a sectnums -a sectnumoffset=1 lib/sectnumoffset-treeprocessor/sample.adoc
  #
  #
  treeprocessor do
    process do |document|
      if (document.attr? 'sectnums') && (sectnumoffset = (document.attr 'sectnumoffset', 0).to_i) > 0
        subsectnumoffset = (document.attr 'subsectnumoffset', 0).to_i
        warn "subsectnumoffset: #{subsectnumoffset}".red if $VERBOSE
        section_count = 0
        if subsectnumoffset > 0
          warn "Insert parent section at 'head' of document with offset #{sectnumoffset}".cyan if $VERBOSE
        end
        ((document.find_by context: :section) || []).each do |sect|
          next unless sect.level <= 2
          if sect.level == 1
            section_count += 1
            sect.number += sectnumoffset
          elsif sect.level == 2 && section_count == 1
            sect.number += subsectnumoffset
          end
        end
      end
      nil
    end
  end
end

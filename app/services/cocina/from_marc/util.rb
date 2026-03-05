# frozen_string_literal: true

module Cocina
  module FromMarc
    # Utilities for MARC manipulation
    class Util
      def self.strip_punctuation(value)
        # Remove set of punctuation characters at the end of the subfield
        escaped_chars = Regexp.escape(':;/[, ')
        regex = /[#{escaped_chars}]+\z/
        value.gsub(regex, '')
      end

      # Parse a MARC 880$6
      # See https://www.loc.gov/marc/bibliographic/ecbdcntf.html
      def self.linked_field(marc, field)
        pointer = field.subfields.find { |subfield| subfield.code == '6' }
        return unless pointer

        # Subfield $6 is formatted thusly:
        #  $6 [linking tag]-[occurrence number]/[script identification code]/[field orientation code]
        #
        # NOTE: "The function of an occurrence number is to permit the matching
        #       of the associated fields (not to sequence the fields within the
        #       record). An occurrence number may be assigned at random for each
        #       set of associated fields."
        linking_tag, occurrence_number = pointer.value.split(%r{-|/})

        marc.fields(linking_tag).find do |linked_field|
          linked_field.subfields.find do |subfield|
            # The first six characters of 880$6 values should always be a
            # three-digit MARC tag, followed by the `-` delimiter, followed by a
            # two-digit occurrence number
            subfield.code == '6' && subfield.value.slice(0..5) == "#{field.tag}-#{occurrence_number}"
          end
        end
      end
    end
  end
end

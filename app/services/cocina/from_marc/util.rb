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
        linking_tag, occurrence_number = pointer.value.split(%r{-|/})
        marc.fields(linking_tag)[occurrence_number.to_i - 1]
      end
    end
  end
end

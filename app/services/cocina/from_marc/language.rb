# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps language information from MARC records to Cocina models.
    class Language
      VALID_CODES = YAML.load_file(::File.join(__dir__, 'marc_languages.yml')).fetch('marc_languages')

      # @see #initialize
      # @see #build
      def self.build(...)
        new(...).build
      end

      # @param [MARC::Record] marc MARC record from FOLIO
      def initialize(marc:)
        @marc = marc
      end

      # 008/35-37, 041 $a, $b, $d, $e, $f, $g, $h, $j
      # @return [Array<Hash>] an array of language hashes
      def build
        (lang_from008 + lang_from041).uniq.compact
          .filter_map { |code| { code: code } if valid_language_code(code) }
      end

      private

      # @param [String] code language code
      # @return [String] the code passed in, if found in the list of valid codes
      def valid_language_code(code)
        code if VALID_CODES.include?(code)
      end

      def lang_from041
        return [] unless marc['041']

        marc['041'].subfields.map do |subfield|
          subfield.value if %w[a b d e f g h j].include?(subfield.code)
        end
      end

      def lang_from008
        return [] unless marc['008']

        [marc['008'].value[35..37]]
      end

      attr_reader :marc
    end
  end
end

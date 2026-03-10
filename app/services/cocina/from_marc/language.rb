# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps language information from MARC records to Cocina models.
    class Language
      VALID_CODES = YAML.load_file(::File.join(__dir__, 'marc_languages.yml')).fetch('marc_languages')
      DEFAULT_SOURCE = 'iso639-2b'

      Lang = Struct.new(:code, :source)

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
        (lang_from008 + lang_from041).map { |lang| { code: lang.code, source: { code: lang.source } } }.uniq.compact
      end

      private

      # @param [String] code language code
      # @return [Boolean] is the code found in the list of valid codes?
      def valid_language_code?(code)
        VALID_CODES.include?(code)
      end

      def lang_from041 # rubocop:disable Metrics/AbcSize
        return [] unless marc['041']

        marc.fields.select { it.tag == '041' }.map do |field|
          source = field['2'] || DEFAULT_SOURCE
          field.subfields.filter_map do |subfield|
            if %w[a b d e f g h i j k m n p q r t].include?(subfield.code) && valid_language_code?(subfield.value)
              Lang.new(code: subfield.value, source:)
            end
          end
        end.flatten.compact
      end

      def lang_from008
        return [] unless marc['008']

        code = marc['008'].value[35..37]
        return [] unless valid_language_code?(code)

        [Lang.new(code:, source: DEFAULT_SOURCE)]
      end

      attr_reader :marc
    end
  end
end

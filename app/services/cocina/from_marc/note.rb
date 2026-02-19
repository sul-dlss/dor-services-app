# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps notes
    class Note
      # MARC fields that should be mapped to notes
      # For fields with special methods, use nil for codes
      # For fields with simple note mapping, provide codes array
      # For fields with typed notes, provide codes and type in a hash
      NOTE_FIELDS = {
        '245' => { codes: %w[c], type: 'statement of responsibility' },
        '362' => { codes: %w[a z], type: 'date/sequential designation' }, # special: dates_of_publication
        '500' => %w[3 a],
        '501' => ['a'],
        '502' => { codes: %w[g b c d o], type: 'thesis' },
        '504' => { codes: %w[a b], type: 'bibliography' },
        '505' => { codes: %w[a g r t u], type: 'table of contents' },
        '506' => { codes: %w[3 a b c d e f g q u], type: 'access restriction' },
        '507' => %w[a b],
        '508' => { codes: %w[3 a], type: 'creation/production credits' },
        '510' => { codes: %w[a b c u x 3], type: 'citation/reference' },
        '511' => { codes: %w[3 a], type: 'performers' },
        '513' => %w[a b],
        '514' => %w[a b c d e f g h i j k m u z],
        '515' => { codes: ['a'], type: 'numbering' },
        '516' => ['a'],
        '518' => { codes: %w[a d o p 3], type: 'venue' },
        '520' => nil, # special: build_summary_note
        '521' => { codes: %w[a b 3], type: 'target audience' },
        '522' => ['a'],
        '524' => { codes: %w[a 3], type: 'preferred citation' },
        '525' => ['a'],
        '526' => { codes: %w[a b c d i z], type: nil }, # Omit $x
        '530' => { codes: %w[a b c d u 3], type: 'additional physical form' },
        '532' => %w[a 3],
        '533' => { codes: %w[a b c d e f m n y 3], type: 'reproduction' },
        '534' => %w[a b c e f k l m n o p t x z 3],
        '535' => { codes: %w[3 a b c d g], type: 'original location' },
        '536' => { codes: %w[a b c d e f g h], type: 'funding' },
        '538' => { codes: ['a'], type: 'system details' },
        '540' => { codes: %w[a b c d f g q u 3], type: 'use and reproduction' },
        '541' => { codes: %w[a b c d e f h n o 3], type: 'acquisition' },
        '542' => { codes: %w[a b c d e f g h i j k l m n o p q r s u 3], type: 'copyright' },
        '544' => %w[a b c d e n 3],
        '545' => { codes: %w[a b u], type: 'biographical/historical' },
        '546' => { codes: %w[a b 3], type: 'language' },
        '547' => ['a'],
        '550' => ['a'],
        '552' => %w[a b c d e f g h i j k l m n o p u z],
        '555' => %w[a b c d u 3],
        '556' => %w[a z],
        '561' => { codes: %w[a u 3], type: 'ownership' },
        '562' => { codes: %w[a b c d e 3], type: 'version identification' },
        '563' => { codes: %w[a u 3], type: 'binding' },
        '565' => %w[a b c d e 3],
        '567' => %w[a b],
        '580' => ['a'],
        '581' => { codes: %w[a z 3], type: 'publications' },
        '583' => { codes: %w[a b c d e f h i j k l n o u z 3], type: 'action' },
        '584' => %w[3 a b 3],
        '585' => { codes: %w[a 3], type: 'exhibitions' },
        '586' => %w[a 3],
        '588' => ['a'],
        '590' => ['a'],
        '795' => { codes: %w[a], type: 'provenance' }
      }.freeze

      # @param [MARC::Record] marc MARC record from FOLIO
      # @return [Hash] a hash that can be mapped to a cocina model
      def self.build(marc:)
        new(marc:).build
      end

      def initialize(marc:)
        @marc = marc
      end

      def build
        notes = []

        # All note fields including 245 (statement of responsibility), 362 (dates), 500-590 (notes),
        # and 795 (local collection)
        NOTE_FIELDS.each do |tag, config|
          marc.fields(tag).each do |field|
            note = build_note_from_field(field, config)
            notes << note if note

            linked = Util.linked_field(marc, field)
            if linked
              linked_note = build_note_from_field(linked, config)
              notes << linked_note if linked_note
            end
          end
        end

        notes.compact
      end

      private

      attr_reader :marc

      def tag_for880(field)
        pointer = field.subfields.find { |sf| sf.code == '6' }
        return nil unless pointer

        pointer.value.split('-').first
      end

      def build_note_from_field(field, config) # rubocop:disable Metrics/MethodLength
        tag = field.tag
        # For 880 fields, use the original tag from the $6 subfield
        if tag == '880'
          tag = tag_for880(field)

          # Get the config for the original tag
          config = NOTE_FIELDS[tag]
        end

        # Handle fields with special methods
        case tag
        when '520'
          return build_summary_note(field)
        when '541', '561', '583'
          return nil if field.indicator1 == '0' # Skip if indicator 1 is 0 for certain fields
        end

        # Handle fields with config-driven mapping
        return nil if config.nil?

        if config.is_a?(Hash)
          # Has codes and possibly a type
          build_note(field, config[:codes], config[:type])
        else
          # Just codes, no type
          build_simple_note(field, config)
        end
      end

      def build_simple_note(field, codes)
        codes = Array(codes)
        values = []
        field.subfields.each do |sf|
          next if sf.code == '6'

          values << sf.value if codes.include?(sf.code)
        end
        return nil if values.empty?

        { value: values.join(' ') }
      end

      def build_note(field, codes, type)
        codes = Array(codes)
        values = []
        field.subfields.each do |sf|
          next if sf.code == '6'

          values << sf.value if codes.include?(sf.code)
        end
        return nil if values.empty?

        result = { value: values.join(' ') }
        result[:type] = type if type
        result
      end

      def build_summary_note(field)
        values = []
        field.subfields.each do |sf|
          next if sf.code == '6'

          values << sf.value if %w[3 a b c u].include?(sf.code)
        end
        return nil if values.empty?

        type = field.indicator1 == '4' ? 'content warning' : 'summary'
        { value: values.join(' '), type: type }
      end
    end
  end
end

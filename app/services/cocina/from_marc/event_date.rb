# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps event date information from MARC 008 field to Cocina
    #
    # 008/06 values are as follows:
    #
    #  * Indicating multiple dates: c, d, i, k, m, p, q, r, t, u
    #  * Indicating single date: s (assumed single if space character or filler character, |)
    #  * Indicating no date: n
    #
    # When the terminal date is open-ended (9999) or unknown (uuuu), map to a
    # single-value structured date with only a `start` value.
    class EventDate
      OPEN_ENDED_DATE = '9999'
      UNKNOWN_DATE = 'uuuu'
      BLANK_DATE = '||||'
      SIMPLE_RANGE_TYPES = %w[m].freeze
      STRUCTURED_RANGE_TYPES = %w[c d i k q u].freeze

      # @see #initialize
      # @see #build
      def self.build(...)
        new(...).build
      end

      # @param record_type [String] the type of event being mapped, e.g. "publication", "creation"
      # @param field [MARC::ControlField] the MARC control field containing event date information (008)
      def initialize(record_type:, field:)
        @type = record_type
        @date_code = field.value[6]
        @start_date = normalize_date(field.value[7..10])
        @end_date = normalize_date(field.value[11..14])
      end

      # @return [Array<Hash>] an array of event date hashes
      def build
        return if no_date?
        return structured_open_range if open_range?
        return simple_range if simple_range?
        return structured_range if structured_range?
        return single_date if start_date

        nil
      end

      private

      attr_reader :type, :date_code, :start_date, :end_date

      def no_date?
        date_code == 'n'
      end

      def open_range?
        start_date && [OPEN_ENDED_DATE, UNKNOWN_DATE].include?(end_date)
      end

      def simple_range?
        SIMPLE_RANGE_TYPES.include?(date_code)
      end

      def structured_range?
        STRUCTURED_RANGE_TYPES.include?(date_code)
      end

      def qualifier
        return 'questionable' if date_code == 'q'

        nil
      end

      def single_date
        [date_hash(start_date)]
      end

      def simple_range
        return single_date unless end_date

        [date_hash(start_date), date_hash(end_date)]
      end

      def structured_open_range
        [
          {
            structuredValue: [
              { value: start_date, type: 'start' }
            ],
            type:,
            encoding: { code: 'marc' }
          }
        ]
      end

      def structured_range
        return unless start_date && end_date

        [
          {
            structuredValue: [
              { value: start_date, type: 'start' },
              { value: end_date, type: 'end' }
            ],
            type:,
            qualifier:,
            encoding: { code: 'marc' }
          }.compact
        ]
      end

      def date_hash(value)
        { value:, type:, encoding: { code: 'marc' } }
      end

      def normalize_date(date)
        return if date.blank? || date == BLANK_DATE

        date
      end
    end
  end
end

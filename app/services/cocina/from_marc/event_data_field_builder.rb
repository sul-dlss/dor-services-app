# frozen_string_literal: true

module Cocina
  module FromMarc
    # Builds a Cocina event hash from a MARC data field using configured
    # subfield mappings for locations, contributors, and dates.
    class EventDataFieldBuilder
      # @see #initialize
      # @see #build
      def self.build(...)
        new(...).build
      end

      def initialize(field:, type:, role:, location_codes:, contributor_codes:, date_code:, # rubocop:disable Metrics/ParameterLists
                     strip_date_punctuation: true)
        @field = field
        @type = type
        @role = role
        @location_codes = location_codes
        @contributor_codes = contributor_codes
        @date_code = date_code
        @strip_date_punctuation = strip_date_punctuation
      end

      def build
        {
          type:,
          location: locations,
          contributor: contributors,
          date:
        }.compact_blank
      end

      private

      attr_reader :field, :type, :role, :location_codes, :contributor_codes, :date_code, :strip_date_punctuation

      def locations
        values_for(*location_codes).map { |value| { value: Util.strip_punctuation(value) } }.presence
      end

      def contributors
        values = values_for(*contributor_codes)
        return if values.blank?

        values.map do |value|
          {
            name: [{ value: Util.strip_punctuation(value) }],
            role: role_value
          }.compact_blank
        end
      end

      def role_value
        [{ value: role }] if role.present?
      end

      def date
        value = field.subfields.find { it.code == date_code }&.value
        return if value.blank?

        value = value.delete_suffix('.') if strip_date_punctuation
        [{ value:, type: }.compact_blank]
      end

      def values_for(*codes)
        field.subfields.filter_map { |subfield| subfield.value if codes.include?(subfield.code) }
      end
    end
  end
end

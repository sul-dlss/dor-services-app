# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps event information from MARC records to Cocina models.
    class Event
      # @see #initialize
      # @see #build
      def self.build(...)
        new(...).build
      end

      # @param [MARC::Record] marc MARC record from FOLIO
      def initialize(marc:)
        @marc = marc
      end

      # @return [Array<Hash>] an array of event hashes
      def build # rubocop:disable Metrics/AbcSize
        [
          publication_from008,
          publication(marc['260']),
          manufacture(marc['260']),
          production(marc['264']),
          edition_statement(marc['250']),
          frequency_statement(marc['310']),
          mode_of_issuance(marc['334'])
        ].flatten.compact
      end

      MARC_264_INDICATOR2 = {
        '0' => { type: 'production', role: 'producer' },
        '1' => { type: 'publication', role: 'publisher' },
        '2' => { type: 'distribution', role: 'distributor' },
        '3' => { type: 'manufacture', role: 'manufacturer' },
        '4' => { type: 'copyright notice', role: '' },
        ' ' => { type: nil, role: nil }
      }.freeze

      private

      def publication_from008 # rubocop:disable Metrics/AbcSize
        field = marc['008']
        return unless field

        type = %w[d f p t].include?(marc.leader[6]) ? 'creation' : 'publication'

        dates = case field.value[6]
                when 'm'
                  [{ value: field.value[7..10], type:, encoding: { code: 'marc' } },
                   { value: field.value[11..14], type:, encoding: { code: 'marc' } }]
                when 'c', 'd', 'i', 'k', 'u'
                  [{
                    structuredValue: [{ value: field.value[7..10], type: 'start' },
                                      { value: field.value[11..14], type: 'end' }],
                    type:, encoding: { code: 'marc' }
                  }]
                else
                  [{ value: field.value[7..10], type:, encoding: { code: 'marc' } }]
                end
        { type:, date: dates }
      end

      def production(field)
        return unless field

        fields = [build_production(field)]
        alt_script_field = Util.linked_field(marc, field)
        fields << build_production(alt_script_field) if alt_script_field
        fields
      end

      def build_production(field) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
        indicator = MARC_264_INDICATOR2.fetch(field.indicator2)
        return copyright(field) if indicator[:type] == 'copyright notice'

        location = field.subfields.find { it.code == 'a' }&.value
        contributors = field.subfields.select { it.code == 'b' }.map(&:value)
        date = field.subfields.find { it.code == 'c' }.value.delete_suffix('.')

        event = { type: indicator[:type] }.compact_blank
        event[:location] = [{ value: Util.strip_punctuation(location) }] if location
        contributor_template = indicator[:role] ? { role: [{ value: indicator[:role] }] } : {}
        if contributors.present?
          event[:contributor] = contributors.map do |contributor|
            contributor_template.merge({ name: [{ value: Util.strip_punctuation(contributor) }] })
          end
        end

        event[:date] = [{ value: date, type: indicator[:type] }.compact_blank]

        event
      end

      def copyright(field)
        date = field.subfields.find { it.code == 'c' }.value.delete_suffix('.')

        { type: 'copyright notice', note: [{ value: date, type: 'copyright statement' }] }
      end

      def edition_statement(field)
        return unless field

        fields = [build_edition_statement(field)]
        alt_script_field = Util.linked_field(marc, field)
        fields << build_edition_statement(alt_script_field) if alt_script_field
        fields
      end

      def build_edition_statement(field)
        statement = field.subfields.select { %w[a b].include? it.code }.map(&:value).join(' ')
        { type: 'publication', note: [{ value: statement, type: 'edition' }] }
      end

      def frequency_statement(field)
        return unless field

        statement = field.subfields.find { %w[a].include? it.code }.value
        { type: 'publication', note: [{ value: statement, type: 'frequency' }] }
      end

      def mode_of_issuance(field)
        return unless field

        statement = field.subfields.find { %w[a].include? it.code }.value
        { note: [{ value: statement, type: 'issuance' }] }
      end

      def publication(field)
        return unless field

        fields = [build_publication(field)]
        alt_script_field = Util.linked_field(marc, field)
        fields << build_publication(alt_script_field) if alt_script_field
        fields
      end

      def build_publication(field) # rubocop:disable Metrics/AbcSize
        publication_locations = field.subfields.filter_map { Util.strip_punctuation(it.value) if it.code == 'a' }
        publisher = field.subfields.find { it.code == 'b' }&.value
        publication_date = field.subfields.find { it.code == 'c' }.value.delete_suffix('.')

        {
          type: 'publication',
          location: publication_locations.map { { value: it } },
          contributor: [{ name: [{ value: Util.strip_punctuation(publisher) }], role: [{ value: 'publisher' }] }],
          date: [{ value: publication_date, type: 'publication' }]
        }
      end

      def manufacture(field) # rubocop:disable Metrics/PerceivedComplexity,Metrics/AbcSize,Metrics/CyclomaticComplexity
        return unless field

        manufacture_location = field.subfields.find { |subfield| subfield.code == 'e' }&.value
        manufacturer = field.subfields.find { |subfield| subfield.code == 'f' }&.value
        return nil unless manufacture_location || manufacturer

        manufacture_date = field.subfields.find { |subfield| subfield.code == 'g' }&.value
        {
          type: 'manufacture',
          location: [{ value: Util.strip_punctuation(manufacture_location) }],
          contributor: [{ name: [{ value: Util.strip_punctuation(manufacturer) }] }],
          date: [{ value: manufacture_date, type: 'manufacture' }]
        }
      end

      attr_reader :marc
    end
  end
end

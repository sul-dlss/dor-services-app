# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps event information from MARC records to Cocina models.
    class Event
      MARC_264_INDICATOR2 = {
        '0' => { type: 'production', role: 'creator' },
        '1' => { type: 'publication', role: 'publisher' },
        '2' => { type: 'distribution', role: 'distributor' },
        '3' => { type: 'manufacture', role: 'manufacturer' },
        '4' => { type: 'copyright notice', role: '' },
        ' ' => { type: nil, role: nil }
      }.freeze

      FREQUENCY_TAGS = %w[310 321].freeze
      CREATION_RECORD_TYPES = %w[d f p t].freeze

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
      def build
        [
          event_from_008,
          publication_events,
          manufacture_event,
          marc_264_events,
          edition_events,
          frequency_event,
          issuance_event
        ].flatten.compact
      end

      private

      attr_reader :marc

      def event_from_008 # rubocop:disable Naming/VariableNumber
        field = marc['008']
        return unless field

        type = CREATION_RECORD_TYPES.include?(marc.leader[6]) ? 'creation' : 'publication'
        date = EventDate.build(record_type: type, field:)

        return if date.blank?

        { type:, date: }
      end

      def publication_events
        build_linked_events(marc['260']) do |field|
          EventDataFieldBuilder.build(
            field:,
            type: 'publication',
            role: 'publisher',
            location_codes: ['a'],
            contributor_codes: ['b'],
            date_code: 'c'
          )
        end
      end

      def manufacture_event
        field = marc['260']
        return unless field

        EventDataFieldBuilder.build(
          field:,
          type: 'manufacture',
          role: 'manufacturer',
          location_codes: ['e'],
          contributor_codes: ['f'],
          date_code: 'g',
          strip_date_punctuation: false
        )
      end

      def marc_264_events
        marc.fields.filter_map do |field|
          build_linked_events(field) { |script_field| build_marc_264_event(script_field) } if field.tag == '264'
        end
      end

      def build_marc_264_event(field)
        indicator = MARC_264_INDICATOR2.fetch(field.indicator2)
        return copyright_event(field) if indicator[:type] == 'copyright notice'

        EventDataFieldBuilder.build(
          field:,
          type: indicator[:type],
          role: indicator[:role],
          location_codes: ['a'],
          contributor_codes: ['b'],
          date_code: 'c'
        )
      end

      def copyright_event(field)
        date = Util.subfield_value(field, 'c')&.delete_suffix('.')
        return if date.blank?

        { type: 'copyright notice', note: [{ value: date, type: 'copyright statement' }] }
      end

      def edition_events
        build_linked_events(marc['250']) do |field|
          statement = joined_subfield_values(field, 'a', 'b')
          { type: 'publication', note: [{ value: statement, type: 'edition' }] } if statement.present?
        end
      end

      def frequency_event
        notes = marc.fields.filter_map do |field|
          next unless FREQUENCY_TAGS.include?(field.tag)

          build_linked_events(field) do |script_field|
            value = joined_subfield_values(script_field, 'a', 'b')
            { value:, type: 'frequency' } if value.present?
          end
        end.flatten.compact

        { type: 'publication', note: notes } if notes.present?
      end

      def issuance_event
        field = marc['334']
        return unless field

        statement = Util.subfield_value(field, 'a')
        return unless statement

        { note: [{ value: statement, type: 'issuance' }] }
      end

      def build_linked_events(field, &)
        return unless field

        [field, Util.linked_field(marc, field)].compact.map(&)
      end

      def joined_subfield_values(field, *codes)
        field.subfields.select { |subfield| codes.include?(subfield.code) }.map(&:value).join(' ')
      end
    end
  end
end

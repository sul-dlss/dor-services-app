# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps contributor information from MARC records to Cocina models.
    class Contributor
      # @see #initialize
      # @see #build
      def self.build(...)
        new(...).build
      end

      # @param [MARC::Record] marc MARC record from FOLIO
      def initialize(marc:)
        @marc = marc
      end

      # @return [Array<Hash>] an array of contributor hashes
      def build # rubocop:disable Metrics/AbcSize
        [
          personal(marc['100'], primary: true),
          corporate(marc['110'], primary: true),
          event(marc['111'], primary: true),
          marc.fields.filter_map { personal(it) if %w[700 720].include?(it.tag) },
          marc.fields.filter_map { corporate(it) if it.tag == '710' },
          marc.fields.filter_map { event(it) if it.tag == '711' }
        ].flatten.compact
      end

      private

      def personal(field, primary: false)
        return unless field

        linked_field = Util.linked_field(marc, field)

        fields = [build_personal(field, primary:)]
        fields << build_personal(linked_field) if linked_field
        fields
      end

      def build_personal(field, primary: false)
        name_type = case field.indicator1
                    when '1', '2'
                      'person'
                    when '3'
                      'family'
                    end
        contributor = { type: name_type }.compact
        contributor[:name] = [build_personal_name(field)]
        contributor[:role] = build_roles(field)
        id = build_id(field).first
        contributor[:identifier] = [{ uri: id, type: 'ORCID' }.compact_blank] if id&.start_with? 'https://orcid.org/'
        contributor[:status] = 'primary' if primary
        contributor.compact_blank
      end

      def build_personal_name(field)
        return unless field

        name = Util.strip_punctuation(field.subfields.select do |subfield|
          %w[a c q d].include? subfield.code
        end.map(&:value).join(' '))
        { value: name }
      end

      def build_id(field)
        field.subfields.select { |subfield| %w[1].include? subfield.code }.map(&:value)
      end

      def build_roles(field, code: 'e') # rubocop:disable Metrics/AbcSize
        expanded = field.subfields.select { |sf| sf.code == '4' }
                                  .map { |role| { value: MARC_RELATORS[role.value] }.compact_blank }

        (field.subfields.select { |sf| sf.code == code }.map { |role| { value: role.value.sub(/.$/, '') } } +
          expanded).uniq.compact_blank
      end

      def corporate(field, primary: false)
        return unless field

        linked_field = Util.linked_field(marc, field)

        fields = [build_corporate(field, primary:)]
        fields << build_corporate(linked_field) if linked_field
        fields
      end

      def build_corporate(field, primary: false) # rubocop:disable Metrics/AbcSize
        contributor = { type: 'organization' }
        name = field.subfields.select { |subfield| %w[a b q d].include? subfield.code }.map(&:value).join(' ')
        contributor[:name] = [{ value: name }]
        id = build_id(field).first
        contributor[:identifier] = [{ uri: id }] if id
        roles = build_roles(field)
        contributor[:role] = roles if roles.present?
        contributor[:status] = 'primary' if primary
        contributor
      end

      def event(field, primary: false)
        return unless field

        linked_field = Util.linked_field(marc, field)

        fields = [build_event(field, primary:)]
        fields << build_event(linked_field) if linked_field
        fields
      end

      def build_event(field, primary: false)
        contributor = { type: 'event' }
        name = field.subfields.select do |subfield|
          %w[a n d c].include? subfield.code
        end.map(&:value).join(' ').delete_suffix(',')
        contributor[:name] = [{ value: name }]
        roles = build_roles(field, code: 'j')
        contributor[:role] = roles if roles.present?
        contributor[:status] = 'primary' if primary
        contributor
      end

      attr_reader :marc
    end
  end
end

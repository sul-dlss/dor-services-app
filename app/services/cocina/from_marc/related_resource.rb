# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps relatedResource information from MARC records to Cocina models.
    class RelatedResource
      # @see #initialize
      # @see #build
      def self.build(...)
        new(...).build
      end

      # @param [MARC::Record] marc MARC record from FOLIO
      def initialize(marc:)
        @marc = marc
      end

      # @return [Array<Hash>] an array of relatedResource hashes
      def build # rubocop:disable Metrics/AbcSize
        [
          in_series(marc['490']),
          marc.fields.select { it.tag == '700' }.map { has_part(it) }.compact,
          marc.fields.select { it.tag == '700' }.map { related_title(it) }.compact,
          has_part_corporate(marc['710']),
          related_to_meeting(marc['711'])
        ].flatten.compact_blank
      end

      private

      def in_series(field)
        return unless field

        { type: 'in series', title: [field['3'], field['a'], field['v'], field['l'], field['x']].join(' ') }
      end

      def has_part(field) # rubocop:disable Naming/PredicatePrefix
        return unless field && field.indicator2 == '2' && field['t']

        contributor = if field.indicator1 == '3'
                        family_contributor(field)
                      else
                        person_contributor(field)
                      end

        body_has_part(field, contributor)
      end

      def has_part_corporate(field) # rubocop:disable Naming/PredicatePrefix
        return unless field && field.indicator2 == '2' && field['t']

        contributor = corporate_contributor(field)
        body_has_part(field, contributor)
      end

      def body_has_part(field, contributor)
        {
          type: 'has part',
          displayLabel: field['i'],
          title: [
            {
              value: [field['t'], field['f'], field['g'], field['k'], field['l'], field['m'], field['n'],
                      field['p'], field['o'], field['r'], field['s']].compact.join(' ')
            }
          ],
          contributor: [contributor]
        }
      end

      def related_title(field)
        return unless field && field.indicator2 != '2' && field['t']

        linked = Util.linked_field(marc, field)
        vals = [build_related_title(field)]
        vals << build_related_title(linked) if linked
        vals
      end

      def build_related_title(field)
        contributor = if field.indicator1 == '3'
                        family_contributor(field)
                      else
                        person_contributor(field)
                      end
        body_related_to(field, contributor)
      end

      def related_to_meeting(field)
        return unless field && field.indicator2 != '2' && field['t']

        contributor = meeting_contributor(field)
        body_related_to(field, contributor)
      end

      def body_related_to(field, contributor)
        {
          type: 'related to',
          displayLabel: field['i'],
          title: [
            {
              value: [field['t'], field['f'], field['g'], field['k'], field['l'], field['m'], field['n'],
                      field['p'], field['o'], field['r'], field['s']].compact.join(' ')
            }
          ],
          contributor: [
            contributor
          ]
        }.compact
      end

      def person_contributor(field) # rubocop:disable Metrics/AbcSize
        name = field.subfields.filter_map do |sf|
          sf.value if %w[a b c d j q].include?(sf.code)
        end.join(' ').delete_suffix(',')
        {
          type: 'person',

          name: [{ value: name }],
          affiliation: [{ value: field['u'] }.compact].compact_blank,
          role: [{ value: field['e']&.delete_suffix('.') }.compact].compact_blank,
          identifier: [{ uri: field['1'] }.compact].compact_blank
        }.compact_blank
      end

      def family_contributor(field) # rubocop:disable Metrics/AbcSize
        {
          type: 'family',
          name: [
            {
              value: [field['a'], field['b'], field['c'], field['d'], field['j'],
                      field['q']].compact.join(' ').delete_suffix(',')
            }
          ],
          affiliation: [{ value: field['u'] }.compact].compact_blank,
          role: [{ value: field['e']&.delete_suffix('.') }.compact].compact_blank,
          identifier: [{ uri: field['1'] }.compact].compact_blank
        }.compact_blank
      end

      def corporate_contributor(field)
        {
          type: 'organization',
          name: [
            {
              value: [field['a'], field['b'], field['c'], field['d']].compact.join(' ').delete_suffix(',')
            }
          ],
          role: [{ value: field['e']&.delete_suffix('.') }.compact].compact_blank,
          identifier: [{ uri: field['1'] }.compact].compact_blank
        }.compact_blank
      end

      def meeting_contributor(field) # rubocop:disable Metrics/AbcSize
        {
          type: 'organization',
          name: [
            {
              value: [field['a'], field['b'], field['c'], field['d'], field['e'],
                      field['q']].compact.join(' ').delete_suffix(',')
            }
          ],
          affiliation: [{ value: field['u'] }.compact].compact_blank,
          role: [{ value: field['j']&.delete_suffix('.') }.compact].compact_blank,
          identifier: [{ uri: field['1'] }.compact].compact_blank
        }.compact_blank
      end

      attr_reader :marc
    end
  end
end

# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps relatedResource information from MARC records to Cocina models.
    class RelatedResource # rubocop:disable Metrics/ClassLength
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
      def build # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
        marc.fields.map do |field|
          case field.tag
          when '490'
            in_series(field)
          when '700'
            [has_part(field), related_title(field)]
          when '710'
            [has_part_corporate(field), related_to_corporate(field)]
          when '711'
            related_to_meeting(field)
          when '730', '740'
            has_part_title(field)
          when '856'
            finding_aid(field)
          end
        end.flatten.compact_blank
      end

      private

      def finding_aid(field)
        return unless field && field.indicator2 == '2' && field['u'].present?

        { access: { url: [{ value: field['u'], displayLabel: field['3'] }.compact_blank] } }
      end

      def in_series(field)
        return unless field

        linked = Util.linked_field(marc, field)
        vals = [build_in_series(field)]
        vals << build_in_series(linked) if linked
        vals
      end

      def build_in_series(field)
        { type: 'in series',
          title: [{ value: [field['3'], field['a'], field['v'], field['l'], field['x']].compact_blank.join(' ') }] }
      end

      def has_part(field) # rubocop:disable Naming/PredicatePrefix
        return unless field && field.indicator2 == '2' && field['t'].present?

        contributor = if field.indicator1 == '3'
                        family_contributor(field)
                      else
                        person_contributor(field)
                      end

        body_has_part(field, contributor)
      end

      def has_part_corporate(field) # rubocop:disable Naming/PredicatePrefix
        return unless field && field.indicator2 == '2' && field['t'].present?

        contributor = corporate_contributor(field)
        body_has_part(field, contributor)
      end

      def related_to_corporate(field)
        return unless field && field.indicator2 != '2' && field['t'].present?

        contributor = corporate_contributor(field)
        body_related_to(field, contributor)
      end

      def body_has_part(field, contributor)
        {
          type: 'has part',
          displayLabel: field['i'],
          title: [
            {
              value: [field['t'], field['f'], field['g'], field['k'], field['l'], field['m'], field['n'],
                      field['p'], field['o'], field['r'], field['s']].compact_blank.join(' ')
            }
          ],
          contributor: [contributor].compact
        }.compact
      end

      def has_part_title(field) # rubocop:disable Naming/PredicatePrefix
        return unless field.indicator2 == '2'

        value = [field['a'], field['h'], field['n'], field['p']].compact_blank.join(' ')
        return if value.blank?

        { type: 'has part', title: [{ value:, type: field.tag == '730' ? 'uniform' : nil }.compact] }
      end

      def related_title(field)
        return unless field && field.indicator2 != '2' && field['t'].present?

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
        return unless field && field.indicator2 != '2' && field['t'].present?

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
                      field['p'], field['o'], field['r'], field['s']].compact_blank.join(' ')
            }
          ],
          contributor: contributor_list(contributor)
        }.compact_blank
      end

      def contributor_list(contributor)
        [contributor].compact.select { |c| c.except(:type).present? }
      end

      def person_contributor(field)
        name = Util.subfield_values(field, %w[a b c d j q]).join(' ').delete_suffix(',')
        {
          type: 'person',

          name: name.present? ? [{ value: name }] : nil,
          affiliation: [{ value: field['u'] }.compact_blank].compact_blank,
          role: [{ value: field['e']&.delete_suffix('.') }.compact_blank].compact_blank,
          identifier: [{ uri: field['1'] }.compact_blank].compact_blank
        }.compact_blank
      end

      def family_contributor(field) # rubocop:disable Metrics/AbcSize
        name = [field['a'], field['b'], field['c'], field['d'],
                field['j'], field['q']].compact_blank.join(' ').delete_suffix(',')
        {
          type: 'family',
          name: name.present? ? [{ value: name }] : nil,
          affiliation: [{ value: field['u'] }.compact_blank].compact_blank,
          role: [{ value: field['e']&.delete_suffix('.') }.compact_blank].compact_blank,
          identifier: [{ uri: field['1'] }.compact_blank].compact_blank
        }.compact_blank
      end

      def corporate_contributor(field)
        name = [field['a'], field['b'], field['c'], field['d']].compact_blank.join(' ').delete_suffix(',')
        {
          type: 'organization',
          name: name.present? ? [{ value: name }] : nil,
          role: [{ value: field['e']&.delete_suffix('.') }.compact_blank].compact_blank,
          identifier: [{ uri: field['1'] }.compact_blank].compact_blank
        }.compact_blank
      end

      def meeting_contributor(field) # rubocop:disable Metrics/AbcSize
        name = [field['a'], field['b'], field['c'], field['d'], field['e'],
                field['q']].compact_blank.join(' ').delete_suffix(',')
        {
          type: 'organization',
          name: name.present? ? [{ value: name }] : nil,
          affiliation: [{ value: field['u'] }.compact_blank].compact_blank,
          role: [{ value: field['j']&.delete_suffix('.') }.compact_blank].compact_blank,
          identifier: [{ uri: field['1'] }.compact_blank].compact_blank
        }.compact_blank
      end

      attr_reader :marc
    end
  end
end

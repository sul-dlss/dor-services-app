# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps titles from MARC to cocina
    class Title
      # @param [MARC::Record] marc MARC record from FOLIO
      # @param [Cocina::Models::Mapping::ErrorNotifier] notifier
      # @return [Hash] a hash that can be mapped to a cocina model
      def self.build(marc:, notifier:)
        new(marc:, notifier:).build_with_validation
      end

      def initialize(marc:, notifier:)
        @marc = marc
        @notifier = notifier
      end

      def build_with_validation
        result = build
        notifier.error('Missing title') if result.nil?

        result
      end

      def build
        return unless valid?
        return basic_title if has_245a_without_non_sorting?

        if field245
          parallel_field = linked_field(field245)
          return parallel_title(parallel_field) if parallel_field
        end

        return alternative_title if alternative_title_field
        return uniform_title if uniform_title_field

        structured_title(field245)
      end

      private

      def valid?
        title_fields = %w[245 246 240 130 740]
        return true if title_fields.any? { |code| marc[code]&.subfields&.any? }

        notifier.warn('No title fields found')
        false
      end

      def field245
        @field245 ||= marc['245']
      end

      def has_245a_without_non_sorting?
        field245 && field245.indicator2 == '0' && field245.subfields.any? { |subfield| subfield.code == 'a' } &&
          field245.subfields.none? { |subfield| %w[b f g k n p s].include? subfield.code }
      end

      def alternative_title_field
        @alternative_title_field ||= marc['246'] || marc['740']
      end

      def alternative_title
        display_label = alternative_title_field.subfields.find { |subfield| subfield.code == 'i' }&.value
        alt_title = [
          {
            value: value_for(alternative_title_field, %w[a b f g k n p s]),
            displayLabel: display_label,
            type: 'alternative'
          }.compact
        ]

        if (link = linked_field(alternative_title_field))
          alt_title << { value: value_for(link, %w[a b f g k n p s]), type: 'alternative' }
        end
        alt_title
      end

      def uniform_title_field
        @uniform_title_field ||= marc['240'] || marc['130']
      end

      def uniform_title
        [{
          value: Util.strip_punctuation(uniform_title_field.select do |subfield|
            %w[a d f g k l m n o p r s t].include? subfield.code
          end.map(&:value).join(' ')),
          type: 'uniform'
        }]
      end

      def linked_field(field)
        pointer = field.subfields.find { |subfield| subfield.code == '6' }
        return unless pointer

        field_id, index = pointer.value.split('-')
        marc.fields(field_id)[index.to_i - 1]
      end

      def basic_title
        title = field245.subfields.find { |subfield| subfield.code == 'a' }
        title_value = Util.strip_punctuation(title.value)
        [{ value: title_value }]
      end

      def structured_title(field) # rubocop:disable Metrics/AbcSize
        return unless field

        title = field.subfields.find { |subfield| subfield.code == 'a' }
        nonsort_count = field.indicator2.to_i
        unless nonsort_count.zero?
          non_sort = { value: Util.strip_punctuation(title.value[0..(nonsort_count - 1)]),
                       type: 'nonsorting characters' }
        end
        sortable = { value: Util.strip_punctuation(title.value[nonsort_count..]), type: 'main title' }
        subtitle = Util.strip_punctuation(field.select do |subfield|
          %w[b f g k n p s].include? subfield.code
        end.map(&:value).join(' '))
        subtitle_node = { value: subtitle, type: 'subtitle' } if subtitle.present?
        [{ structuredValue: [non_sort, sortable, subtitle_node].compact }]
      end

      def parallel_title(linked_field)
        [{ parallelValue: structured_title(field245) + structured_title(linked_field) }]
      end

      def value_for(field, subfields)
        Util.strip_punctuation(field.select { |subfield| subfields.include? subfield.code }.map(&:value).join(' '))
      end

      attr_reader :marc, :notifier
    end
  end
end

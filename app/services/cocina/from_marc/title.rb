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

      def build # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
        return unless valid?

        titles = []
        titles << main_title

        titles += marc.fields.filter_map do |field|
          case field.tag
          when '246'
            alternative_title(field)
          when '740'
            alternative_title(field) if field.indicator2 != '2'
          when '240', '130'
            uniform_title(field)
          when '730'
            uniform_title(field) if field.indicator2 != '2'
          end
        end

        titles.flatten.compact
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

      def main_title
        return unless field245

        parallel_field = Util.linked_field(marc, field245)
        if parallel_field
          parallel_title(parallel_field)
        elsif has_245a_without_non_sorting?
          basic_title
        else
          structured_title(field245)
        end
      end

      def has_245a_without_non_sorting?
        field245 && field245.indicator2 == '0' && field245.subfields.any? { |subfield| subfield.code == 'a' } &&
          field245.subfields.none? { |subfield| %w[b f g k n p s].include? subfield.code }
      end

      def alternative_title(alternative_title_field, type: 'alternative')
        alt_title = [build_alternative_title(alternative_title_field, type:)]
        link = Util.linked_field(marc, alternative_title_field)
        alt_title << build_alternative_title(link, type:) if link
        alt_title
      end

      def build_alternative_title(field, type:)
        display_label = field.subfields.find { |subfield| subfield.code == 'i' }&.value
        {
          value: value_for(field, %w[a b f g k n p s]),
          displayLabel: display_label,
          type:
        }.compact
      end

      # For 130/240/730
      def uniform_title(uniform_title_field)
        titles = [build_uniform_title(uniform_title_field)]
        link = Util.linked_field(marc, uniform_title_field)
        titles << build_uniform_title(link) if link
        titles
      end

      def build_uniform_title(field)
        {
          value: Util.strip_punctuation(field.select do |subfield|
            %w[a d f g i k l m n o p r s t].include? subfield.code
          end.map(&:value).join(' ')),
          type: 'uniform'
        }
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
        subtitle_value = subtitle(field)
        subtitle_node = { value: subtitle_value, type: 'subtitle' } if subtitle_value.present?
        titles = [non_sort, sortable, subtitle_node].compact
        if titles.size == 1
          titles
        else
          [{ structuredValue: [non_sort, sortable, subtitle_node].compact }]
        end
      end

      def subtitle(field)
        Util.strip_punctuation(field.select do |subfield|
          %w[b f g k n p s].include? subfield.code
        end.map(&:value).join(' '))
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

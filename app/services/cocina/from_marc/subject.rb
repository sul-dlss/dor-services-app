# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps Subject to the cocina model
    class Subject # rubocop:disable Metrics/ClassLength
      # @see #initialize
      # @see #build
      def self.build(...)
        new(...).build
      end

      # @param [MARC::Record] marc MARC record from FOLIO
      def initialize(marc:)
        @marc = marc
      end

      # @return [Array<Hash>] a hash that can be mapped to a cocina model
      def build
        [
          lcc_classification,
          sudoc_classification,
          map_coordinates,
          uncontrolled_subjects,
          controlled_subjects
        ].flatten.compact
      end

      private

      attr_reader :marc

      # LCC classification from 050$ab
      def lcc_classification # rubocop:disable Metrics/AbcSize
        marc.fields('050').flat_map do |field|
          subfield_a = field.subfields.find { |sf| sf.code == 'a' }&.value
          subfield_b = field.subfields.find { |sf| sf.code == 'b' }&.value
          next unless subfield_a

          value = [subfield_a, subfield_b].compact.join
          { value: value, type: 'classification', source: { code: 'lcc' } }
        end.compact
      end

      # SUDOC classification from 086$a when ind1=0
      def sudoc_classification
        marc.fields('086').flat_map do |field|
          next unless field.indicator1 == '0'

          subfield_a = field.subfields.find { |sf| sf.code == 'a' }&.value
          next unless subfield_a

          { value: subfield_a, type: 'classification', source: { code: 'sudoc' } }
        end.compact
      end

      # Map coordinates from 255$c
      def map_coordinates
        marc.fields('255').flat_map do |field|
          subfield_c = field.subfields.find { |sf| sf.code == 'c' }&.value
          next unless subfield_c

          { value: subfield_c, type: 'map coordinates' }
        end.compact
      end

      # Uncontrolled subjects from 653
      def uncontrolled_subjects
        marc.fields('653').flat_map do |field|
          results = [build_uncontrolled_subject(field)]
          alt_script_field = Util.linked_field(marc, field)
          results << build_uncontrolled_subject(alt_script_field) if alt_script_field
          results
        end.flatten.compact
      end

      def build_uncontrolled_subject(field) # rubocop:disable Metrics/CyclomaticComplexity
        type = case field.indicator2
               when '1' then 'person'
               when '2' then 'organization'
               when '3' then 'event'
               when '4' then 'time'
               when '5' then 'place'
               when '6' then 'genre'
               else 'topic'
               end

        field.subfields.select { |sf| sf.code == 'a' }.map do |subfield|
          { value: subfield.value, type: type }
        end
      end

      # Controlled subjects from 600, 610, 611, 630, 648, 650, 651
      def controlled_subjects
        [
          process_6xx_fields('600', method(:build_600_subject)),
          process_6xx_fields('610', method(:build_610_subject)),
          process_6xx_fields('611', method(:build_611_subject)),
          process_6xx_fields('630', method(:build_630_subject)),
          process_6xx_fields('648', method(:build_648_subject)),
          process_6xx_fields('650', method(:build_650_subject)),
          process_6xx_fields('651', method(:build_651_subject))
        ].flatten.compact
      end

      def process_6xx_fields(tag, builder)
        marc.fields(tag).flat_map do |field|
          main_results = builder.call(field, return_parts: true)
          alt_script_field = Util.linked_field(marc, field)

          if alt_script_field
            combine_with_alt_script(main_results, builder.call(alt_script_field, return_parts: true))
          else
            [main_results[:main], main_results[:subdivisions]].flatten.compact
          end
        end
      end

      def combine_with_alt_script(main_results, alt_results) # rubocop:disable Metrics/PerceivedComplexity,Metrics/AbcSize,Metrics/CyclomaticComplexity
        combined = []
        combined << main_results[:main] if main_results[:main]

        subdivisions_identical = (main_results[:subdivisions] == alt_results[:subdivisions])

        if subdivisions_identical && main_results[:subdivisions].size == 1
          # If there's exactly one subdivision and it's identical: main1, subdivision, main2
          combined += main_results[:subdivisions]
          combined << alt_results[:main] if alt_results[:main]
        elsif subdivisions_identical
          # If subdivisions are identical: main1, main2, subdivisions (deduplicated)
          combined << alt_results[:main] if alt_results[:main]
          combined += main_results[:subdivisions]
        else
          # If subdivisions are different: main1, subdivisions1, main2, subdivisions2
          combined += main_results[:subdivisions]
          combined << alt_results[:main] if alt_results[:main]
          combined += alt_results[:subdivisions]
        end

        combined
      end

      # Build 600 (Person/Family name subject)
      def build_600_subject(field, return_parts: false)
        has_title = field.subfields.any? { |sf| sf.code == 't' }

        if has_title
          build_title_subject(field, '600', return_parts: return_parts)
        else
          build_name_subject(field, '600', return_parts: return_parts)
        end
      end

      # Build 610 (Organization name subject)
      def build_610_subject(field, return_parts: false)
        has_title = field.subfields.any? { |sf| sf.code == 't' }

        if has_title
          build_title_subject(field, '610', return_parts: return_parts)
        else
          build_name_subject(field, '610', return_parts: return_parts)
        end
      end

      # Build 611 (Event name subject)
      def build_611_subject(field, return_parts: false)
        has_title = field.subfields.any? { |sf| sf.code == 't' }

        if has_title
          build_title_subject(field, '611', return_parts: return_parts)
        else
          build_name_subject(field, '611', return_parts: return_parts)
        end
      end

      # Build 630 (Uniform title subject)
      def build_630_subject(field, return_parts: false)
        build_title_subject(field, '630', return_parts: return_parts)
      end

      # Build 648 (Chronological term subject)
      def build_648_subject(field, return_parts: false)
        main_subfields = field.subfields.select { |sf| %w[a e].include?(sf.code) }
        main_value = main_subfields.map(&:value).join(' ')

        main = main_value.present? ? { value: main_value, type: 'time' } : nil
        subdivisions = build_subdivisions(field)

        return { main: main, subdivisions: subdivisions } if return_parts

        [main, subdivisions].flatten.compact
      end

      # Build 650 (Topical term subject)
      def build_650_subject(field, return_parts: false)
        main_subfields = field.subfields.select { |sf| %w[a b c d e g].include?(sf.code) }
        main_value = main_subfields.map(&:value).join(' ')

        main = main_value.present? ? { value: main_value, type: 'topic' } : nil
        subdivisions = build_subdivisions(field)

        return { main: main, subdivisions: subdivisions } if return_parts

        [main, subdivisions].flatten.compact
      end

      # Build 651 (Geographic name subject)
      def build_651_subject(field, return_parts: false)
        main_subfields = field.subfields.select { |sf| %w[a e g].include?(sf.code) }
        main_value = main_subfields.map(&:value).join(' ')

        main = main_value.present? ? { value: main_value, type: 'place' } : nil
        subdivisions = build_subdivisions(field)

        return { main: main, subdivisions: subdivisions } if return_parts

        [main, subdivisions].flatten.compact
      end

      # Build name subject (600 without $t, 610 without $t, 611 without $t)
      def build_name_subject(field, tag, return_parts: false)
        type = determine_name_type(field, tag)
        subfield_codes = name_subfield_codes[tag]

        main_subfields = field.subfields.select { |sf| subfield_codes.include?(sf.code) }
        main_value = main_subfields.map(&:value).join(' ')

        main = main_value.present? ? { value: main_value, type: type } : nil
        subdivisions = build_subdivisions(field)

        return { main: main, subdivisions: subdivisions } if return_parts

        [main, subdivisions].flatten.compact
      end

      # Build title subject (600 with $t, 610 with $t, 611 with $t, 630)
      def build_title_subject(field, tag, return_parts: false)
        subfield_codes = title_subfield_codes[tag]

        main_subfields = field.subfields.select { |sf| subfield_codes.include?(sf.code) }
        main_value = main_subfields.map(&:value).join(' ')

        main = main_value.present? ? { value: main_value, type: 'title' } : nil
        subdivisions = build_subdivisions(field)

        return { main: main, subdivisions: subdivisions } if return_parts

        [main, subdivisions].flatten.compact
      end

      # Determine name type based on field and indicators
      def determine_name_type(field, tag)
        case tag
        when '600'
          field.indicator1 == '3' ? 'family' : 'person'
        when '610'
          'organization'
        when '611'
          'event'
        end
      end

      def name_subfield_codes
        {
          '600' => %w[a b c d e f g h j k l m n o p q r s u],
          '610' => %w[a b c d e f g h k l m n o p r s u],
          '611' => %w[a c d e f g h j k l n p q s u]
        }
      end

      def title_subfield_codes
        {
          '600' => %w[a b c d e f g h j k l m n o p q r s t u],
          '610' => %w[a b c d e f g h k l m n o p r s t u],
          '611' => %w[a c d e f g h j k l n p q s t u],
          '630' => %w[a d e f g h k l m n o p r s t]
        }
      end

      # Build subdivisions (v, x, y, z)
      def build_subdivisions(field) # rubocop:disable Metrics/PerceivedComplexity,Metrics/AbcSize,Metrics/CyclomaticComplexity
        results = []

        # Topic subdivisions ($x)
        results += field.subfields.select { |sf| sf.code == 'x' }.map do |sf|
          { value: sf.value, type: 'topic' }
        end

        # Time subdivisions ($y)
        results += field.subfields.select { |sf| sf.code == 'y' }.map do |sf|
          { value: sf.value, type: 'time' }
        end

        # Place subdivisions ($z)
        results += field.subfields.select { |sf| sf.code == 'z' }.map do |sf|
          { value: sf.value, type: 'place' }
        end

        # Form subdivisions ($v)
        results += field.subfields.select { |sf| sf.code == 'v' }.map do |sf|
          { value: sf.value, type: 'genre' }
        end

        results
      end
    end
  end
end

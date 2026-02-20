# frozen_string_literal: true

module Cocina
  module FromMarc
    # Maps form information from MARC records to Cocina models.
    class Form # rubocop:disable Metrics/ClassLength
      # @see #initialize
      # @see #build
      def self.build(...)
        new(...).build
      end

      # @param [MARC::Record] marc MARC record from FOLIO
      def initialize(marc:)
        @marc = marc
      end

      # @return [Array<Hash>] an array of form hashes
      def build # rubocop:disable Metrics/AbcSize
        [
          [build_extent(marc['300'], %w[a b c e f g 3])],
          build_physical_medium(marc['340']),
          build_sound_characteristics(marc['344']),
          build_organization_and_arrangement(marc['351']),
          build_genre_form(marc['655']),
          build_cartographic(marc['255']),
          marc.fields.select { it.tag == '336' }.map { build_content_type(it) },
          build_resource_types,
          build_dataset_genre

        ].flatten.compact
      end

      PHYSICAL_MEDIUM_FIELDS = {
        'a' => 'Material base and configuration',
        'b' => 'Dimensions',
        'c' => 'Materials applied to surface',
        'd' => 'Information recording technique',
        'i' => 'Technical specifications of medium',
        'j' => 'Generation'
      }.freeze

      SOUND_CHARACTERISTICS = {
        'a' => 'Type of recording',
        'b' => 'Recording medium',
        'c' => 'Playing speed',
        'd' => 'Groove characteristic',
        'e' => 'Track configuration',
        'f' => 'Tape configuration',
        'g' => 'Configuration of playback channels',
        'h' => 'Special playback characteristics'
      }.freeze

      private

      def build_extent(field, codes)
        return unless field

        codes = Array(codes)
        values = []
        field.subfields.each do |sf|
          next if sf.code == '6'

          values << sf.value if codes.include?(sf.code)
        end
        return nil if values.empty?

        { value: values.join(' '), type: 'extent' }
      end

      def build_physical_medium(field)
        return unless field

        field.subfields.map do |sf|
          value = PHYSICAL_MEDIUM_FIELDS[sf.code]
          next unless value

          { note: [{ value: sf.value, displayLabel: value }] }
        end
      end

      def build_sound_characteristics(field)
        return unless field

        field.subfields.map do |sf|
          value = SOUND_CHARACTERISTICS[sf.code]
          next unless value

          { note: [{ value: sf.value, displayLabel: value }] }
        end
      end

      def build_organization_and_arrangement(field)
        return unless field

        { note: [{ value: [field['3'], field['c'], field['a'], field['b']].join(' '), type: 'arrangement' }] }
      end

      def build_genre_form(field)
        return unless field

        {
          value: field['a'],
          type: 'genre'
        }
      end

      def build_cartographic(field)
        return unless field

        vals = []
        vals << { value: field['a'], type: 'map scale' } if field['a']
        vals << { value: field['b'], type: 'map projection' } if field['b']
        vals.compact
      end

      def build_content_type(field)
        return unless field

        { value: field['a'], type: 'genre' }
      end

      def build_dataset_genre
        return unless marc['008'] && marc['008'].value[26] == 'a' && marc.leader[6] == 'm'

        { value: 'dataset', type: 'genre', source: { code: 'local' } }
      end

      def build_resource_types # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/AbcSize
        return unless marc.leader

        leader06 = marc.leader[6]
        leader07 = marc.leader[7]

        return build_collection_resource_type if leader07 == 'c'

        case leader06
        when 'a'
          build_text_resource_type
        when 'c'
          build_notated_music_resource_type
        when 'd'
          build_manuscript_notated_music_resource_type
        when 'e'
          build_cartographic_resource_type
        when 'f'
          build_manuscript_cartographic_resource_type
        when 'g'
          build_moving_image_resource_type
        when 'i'
          build_sound_nonmusical_resource_type
        when 'j'
          build_sound_musical_resource_type
        when 'k'
          build_still_image_resource_type
        when 'm'
          build_software_multimedia_resource_type
        when 'p'
          build_manuscript_mixed_material_resource_type
        when 'r'
          build_three_dimensional_object_resource_type
        when 't'
          build_manuscript_text_resource_type
        end
      end

      def build_collection_resource_type
        [
          { value: 'collection', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Collection', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_text_resource_type
        [
          { value: 'text', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Text', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_notated_music_resource_type
        [
          { value: 'notated music', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Notated music', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_manuscript_notated_music_resource_type
        [
          { value: 'manuscript', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'notated music', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Manuscript', type: 'resource type', source: { value: 'LC Resource Types Scheme' } },
          { value: 'Notated music', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_cartographic_resource_type
        [
          { value: 'cartographic', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Cartographic', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_manuscript_cartographic_resource_type
        [
          { value: 'manuscript', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'cartographic', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Manuscript', type: 'resource type', source: { value: 'LC Resource Types Scheme' } },
          { value: 'Cartographic', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_moving_image_resource_type
        [
          { value: 'moving image', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Moving image', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_sound_nonmusical_resource_type
        [
          { value: 'sound recording-nonmusical', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Audio', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_sound_musical_resource_type
        [
          { value: 'sound recording-musical', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Audio', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_still_image_resource_type
        [
          { value: 'still image', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Still image', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_software_multimedia_resource_type
        base = [
          { value: 'software, multimedia', type: 'resource type', source: { value: 'MODS resource types' } }
        ]

        base << if marc['008'] && marc['008'].value[26] == 'a'
                  { value: 'Dataset', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
                else
                  { value: 'Digital', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
                end

        base
      end

      def build_manuscript_mixed_material_resource_type
        [
          { value: 'manuscript', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'mixed material', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Manuscript', type: 'resource type', source: { value: 'LC Resource Types Scheme' } },
          { value: 'Mixed material', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_three_dimensional_object_resource_type
        [
          { value: 'three dimensional object', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Artifact', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      def build_manuscript_text_resource_type
        [
          { value: 'manuscript', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'text', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'Manuscript', type: 'resource type', source: { value: 'LC Resource Types Scheme' } },
          { value: 'Text', type: 'resource type', source: { value: 'LC Resource Types Scheme' } }
        ]
      end

      attr_reader :marc
    end
  end
end

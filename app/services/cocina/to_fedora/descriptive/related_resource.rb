# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps relatedResource from cocina to MODS relatedItem
      class RelatedResource
        # see https://docs.google.com/spreadsheets/d/1d5PokzgXqNykvQeckG2ND43B6i9_CsjfIVwS_IsphS8/edit#gid=0
        TYPES = {
          'has original version' => 'original',
          'has other format' => 'otherFormat',
          'has part' => 'constituent',
          'has version' => 'otherVersion',
          'in series' => 'series',
          'part of' => 'host',
          'preceded by' => 'preceding',
          'related to' => nil, # 'related to' is a null type by design
          'reviewed by' => 'reviewOf',
          'referenced by' => 'isReferencedBy',
          'references' => 'references',
          'succeeded by' => 'succeeding'
        }.freeze

        DETAIL_TYPES = {
          'location within source' => 'part',
          'volume' => 'volume',
          'issue' => 'issue',
          'chapter' => 'chapter',
          'section' => 'section',
          'paragraph' => 'paragraph',
          'track' => 'track',
          'marker' => 'marker'
        }.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::RelatedResource>] related_resources
        # @param [string] druid
        # @param [IdGenerator] id_generator
        def self.write(xml:, related_resources:, druid:, id_generator:)
          new(xml: xml, related_resources: related_resources, druid: druid, id_generator: id_generator).write
        end

        def initialize(xml:, related_resources:, druid:, id_generator:)
          @xml = xml
          @related_resources = Array(related_resources)
          @druid = druid
          @id_generator = id_generator
        end

        def write
          filtered_related_resources.each do |(attributes, new_related, _orig_related)|
            xml.relatedItem attributes do
              DescriptiveWriter.write(xml: xml, descriptive: new_related, druid: druid, id_generator: id_generator)
            end
          end

          related_resources.filter(&:valueAt).each do |related_resource|
            xml.relatedItem nil, { 'xlink:href' => related_resource.valueAt }
          end
        end

        private

        attr_reader :xml, :related_resources, :druid, :id_generator

        def filtered_related_resources
          related_resources.map do |related|
            next if related.valueAt

            other_type_note = other_type_note_for(related)

            # Filter notes
            related_hash = related.to_h
            new_notes = related_hash.fetch(:note, []).reject { |note| note[:type] == 'other relation type' }
            related_hash[:note] = new_notes.empty? ? nil : new_notes
            next if related_hash.empty?

            new_related = Cocina::Models::RelatedResource.new(related_hash.compact)

            [attributes_for(related, other_type_note), new_related, related]
          end.compact
        end

        def attributes_for(related, other_type_note)
          {}.tap do |attrs|
            attrs[:type] = TYPES.fetch(related.type) if related.type
            attrs[:displayLabel] = related.displayLabel

            if other_type_note
              attrs[:otherType] = other_type_note.value
              attrs[:otherTypeURI] = other_type_note.uri
              attrs[:otherTypeAuth] = other_type_note.source&.value
            end
          end.compact
        end

        def other_type_note_for(related)
          return nil if related.note.nil?

          related.note.find { |note| note.type == 'other relation type' }
        end
      end
    end
  end
end

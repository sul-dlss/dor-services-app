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
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] related_resources
        # @param [string] druid
        # @param [IdGenerator] id_generator
        def self.write(xml:, related_resources:, druid:, id_generator:)
          new(xml: xml, related_resources: related_resources, druid: druid, id_generator: id_generator).write
        end

        def initialize(xml:, related_resources:, druid:, id_generator:)
          @xml = xml
          @related_resources = related_resources
          @druid = druid
          @id_generator = id_generator
        end

        def write
          Array(related_resources).each do |related|
            other_type_note = other_type_note_for(related)
            attributes = {}.tap do |attrs|
              attrs[:type] = TYPES.fetch(related.type) if related.type
              attrs[:displayLabel] = related.displayLabel

              if other_type_note
                attrs[:otherType] = other_type_note.value
                attrs[:otherTypeURI] = other_type_note.uri
                attrs[:otherTypeAuth] = other_type_note.source&.value
              end
            end.compact

            # Filter out "other relation type"
            related_hash = related.to_h
            if other_type_note
              new_notes = related_hash.fetch(:note, []).reject { |note| note[:type] == 'other relation type' }
              related_hash[:note] = new_notes.empty? ? nil : new_notes
            end
            new_related = Cocina::Models::RelatedResource.new(related_hash.compact)

            xml.relatedItem attributes do
              DescriptiveWriter.write(xml: xml, descriptive: new_related, druid: druid, id_generator: id_generator)
            end
          end
        end

        private

        attr_reader :xml, :related_resources, :druid, :id_generator

        def other_type_note_for(related)
          return nil if related.note.nil?

          related.note.find { |note| note.type == 'other relation type' }
        end
      end
    end
  end
end

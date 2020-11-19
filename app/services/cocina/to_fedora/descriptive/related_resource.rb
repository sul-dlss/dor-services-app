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
        def self.write(xml:, related_resources:, druid:)
          new(xml: xml, related_resources: related_resources, druid: druid).write
        end

        def initialize(xml:, related_resources:, druid:)
          @xml = xml
          @related_resources = related_resources
          @druid = druid
        end

        def write
          Array(related_resources).each do |related|
            attributes = {}
            attributes[:type] = TYPES.fetch(related.type) if related.type
            attributes[:displayLabel] = related.displayLabel if related.displayLabel
            xml.relatedItem attributes.compact do
              DescriptiveWriter.write(xml: xml, descriptive: related, druid: druid)
            end
          end
        end

        private

        attr_reader :xml, :related_resources, :druid
      end
    end
  end
end

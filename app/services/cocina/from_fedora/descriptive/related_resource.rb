# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS relatedItem to cocina relatedResource
      class RelatedResource
        TYPES = ToFedora::Descriptive::RelatedResource::TYPES.invert.freeze

        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @descriptive_builder = descriptive_builder
        end

        def build
          related_items.map do |related_item|
            descriptive_builder.build(resource_element: related_item, require_title: false).tap do |item|
              item[:type] = normalized_type_for(related_item['type']) if related_item['type']
              item[:displayLabel] = related_item['displayLabel']
            end.compact
          end
        end

        private

        attr_reader :resource_element, :descriptive_builder

        def related_items
          resource_element.xpath('mods:relatedItem', mods: DESC_METADATA_NS)
        end

        # Normalize type so we can tolerate certain known data errors, but report anything that is not found or not an exact match
        def normalized_type_for(type)
          return TYPES.fetch(type) if TYPES.key?(type)

          normalized_type = if type.downcase == 'other version'
                              TYPES['otherVersion']
                            elsif type.downcase == 'isreferencedby'
                              TYPES['isReferencedBy']
                            end

          Honeybadger.notify("[DATA ERROR] Invalid related resource type (#{type})", { tags: 'data_error' })
          normalized_type
        end
      end
    end
  end
end

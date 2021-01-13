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
          @notifier = descriptive_builder.notifier
        end

        def build
          related_items.map do |related_item|
            check_other_type(related_item)
            descriptive_builder.build(resource_element: related_item, require_title: false).tap do |item|
              item[:displayLabel] = related_item['displayLabel']
              if related_item['type']
                item[:type] = normalized_type_for(related_item['type'])
              elsif related_item['otherType']
                item[:type] = 'related to'
                item[:note] = [
                  { type: 'other relation type', value: related_item['otherType'] }.tap do |note|
                    note[:uri] = related_item['otherTypeURI'] if related_item['otherTypeURI']
                    note[:source] = { value: related_item['otherTypeAuth'] } if related_item['otherTypeAuth']
                  end
                ]
              end
            end.compact.presence
          end.compact
        end

        private

        attr_reader :resource_element, :descriptive_builder, :notifier

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

          notifier.warn('Invalid related resource type', { resource_type: type })
          normalized_type
        end

        def check_other_type(related_item)
          return unless related_item['type'] && related_item['otherType']

          notifier.warn('Related resource has type and otherType')
        end
      end
    end
  end
end

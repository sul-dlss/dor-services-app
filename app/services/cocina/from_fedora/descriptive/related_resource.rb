# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS relatedItem to cocina relatedResource
      class RelatedResource
        TYPES = ToFedora::Descriptive::RelatedResource::TYPES.invert.freeze
        DETAIL_TYPES = ToFedora::Descriptive::RelatedResource::DETAIL_TYPES.invert.freeze

        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @param [String] purl
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:, purl:)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder, purl: purl).build
        end

        def initialize(resource_element:, descriptive_builder:, purl:)
          @resource_element = resource_element
          @descriptive_builder = descriptive_builder
          @notifier = descriptive_builder.notifier
          @purl = purl
        end

        def build
          related_items + related_purls
        end

        private

        attr_reader :resource_element, :descriptive_builder, :notifier, :purl

        def related_items
          resource_element.xpath('mods:relatedItem', mods: DESC_METADATA_NS).filter_map do |related_item|
            check_other_type(related_item)
            next { valueAt: related_item['xlink:href'] } if related_item['xlink:href']
            next if related_item.elements.empty?

            related_item = build_related_item(related_item)
            # Skip if type only.
            next if related_item.keys == [:type]

            related_item.presence
          end
        end

        def build_related_item(related_item)
          descriptive_builder.build(resource_element: related_item, require_title: false).tap do |item|
            item[:displayLabel] = related_item['displayLabel']
            if related_item['type']
              item[:type] = normalized_type_for(related_item['type'])
            elsif related_item['otherType']
              item[:type] = 'related to'
              item[:note] ||= []
              item[:note] <<
                { type: 'other relation type', value: related_item['otherType'] }.tap do |note|
                  note[:uri] = related_item['otherTypeURI'] if related_item['otherTypeURI']
                  note[:source] = { value: related_item['otherTypeAuth'] } if related_item['otherTypeAuth']
                end
            end
          end.compact
        end

        # Normalize type so we can tolerate certain known data errors, but report anything that is not found or not an exact match
        def normalized_type_for(type)
          return TYPES.fetch(type) if TYPES.key?(type)

          normalized_type = if type.casecmp('other version').zero?
                              TYPES['otherVersion']
                            elsif type.casecmp('isreferencedby').zero?
                              TYPES['isReferencedBy']
                            end

          notifier.warn('Invalid related resource type', { resource_type: type })
          normalized_type
        end

        def check_other_type(related_item)
          return unless related_item['type'] && related_item['otherType']

          notifier.warn('Related resource has type and otherType')
        end

        def related_purls
          primary_purl_node = Descriptive::Purl.primary_purl_node(resource_element, purl)
          purl_nodes = resource_element.xpath('mods:location/mods:url', mods: DESC_METADATA_NS).select { |url_node| ::Purl.purl?(url_node.text) && url_node != primary_purl_node }
          purl_nodes.map do |purl_node|
            {
              purl: Descriptive::Purl.purl_value(purl_node),
              access: {
                note: Purl.purl_note(purl_node).presence
              }.compact.presence
            }.compact
          end
        end
      end
    end
  end
end

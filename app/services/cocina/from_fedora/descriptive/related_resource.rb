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
          resource_element.xpath('mods:relatedItem', mods: DESC_METADATA_NS).map do |related_item|
            check_other_type(related_item)
            next { valueAt: related_item['xlink:href'] } if related_item['xlink:href']
            next nil if related_item.elements.empty?

            related_item = build_related_item(related_item)
            # Skip if type only.
            next nil if related_item.keys == [:type]

            related_item.presence
          end.compact
        end

        def build_related_item(related_item)
          descriptive_builder.build(resource_element: related_item, require_title: false).tap do |item|
            item[:displayLabel] = related_item['displayLabel']
            notes = build_notes(related_item)
            if related_item['type']
              item[:type] = normalized_type_for(related_item['type'])
            elsif related_item['otherType']
              item[:type] = 'related to'
              notes <<
                { type: 'other relation type', value: related_item['otherType'] }.tap do |note|
                  note[:uri] = related_item['otherTypeURI'] if related_item['otherTypeURI']
                  note[:source] = { value: related_item['otherTypeAuth'] } if related_item['otherTypeAuth']
                end
            end
            if notes.present?
              item[:note] ||= []
              item[:note].concat(notes)
            end
          end.compact
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

        def build_notes(related_item)
          related_item.xpath('mods:part', mods: DESC_METADATA_NS).map do |part_node|
            values = []
            values.concat(build_detail_values(part_node))
            values.concat(build_extent_values(part_node))
            values.concat(build_note_value(part_node, 'text'))
            values.concat(build_note_value(part_node, 'date'))

            next nil if values.empty?

            {
              type: 'part',
              groupedValue: values
            }
          end.compact
        end

        def build_detail_values(part_node)
          detail_node = part_node.xpath('mods:detail', mods: DESC_METADATA_NS).first
          return [] unless detail_node

          detail_values = []
          detail_values.concat(build_note_value(detail_node, 'number'))
          detail_values.concat(build_note_value(detail_node, 'caption'))
          detail_values.concat(build_note_value(detail_node, 'title'))
          detail_values.concat(build_note_value(detail_node, 'detail type', xpath: '@type')) if detail_values.present?
          detail_values
        end

        def build_extent_values(part_node)
          extent_node = part_node.xpath('mods:extent', mods: DESC_METADATA_NS).first
          return [] unless extent_node

          extent_values = []
          extent_values.concat(build_note_value(extent_node, 'list'))
          extent_values.concat(build_note_value(extent_node, 'extent unit', xpath: '@unit')) if extent_values.present?
          extent_values
        end

        def build_note_value(node, type, xpath: nil)
          xpath ||= "mods:#{type}"
          node.xpath(xpath, mods: DESC_METADATA_NS).map do |value_node|
            next nil if value_node.content.blank?

            { type: type, value: value_node.content }
          end.compact
        end

        def related_purls
          primary_purl_node = Purl.primary_purl_node(resource_element, purl)
          purl_nodes = resource_element.xpath('mods:location/mods:url', mods: DESC_METADATA_NS).select { |url_node| Purl.purl?(url_node) && url_node != primary_purl_node }
          purl_nodes.map do |purl_node|
            {
              purl: purl_node.content,
              access: {
                note: Purl.purl_note(purl_node).presence,
                digitalRepository: [{ value: 'Stanford Digital Repository' }]
              }.compact
            }.compact
          end
        end
      end
    end
  end
end

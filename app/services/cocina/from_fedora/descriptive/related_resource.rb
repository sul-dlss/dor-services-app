# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS relatedItem to cocina relatedResource
      class RelatedResource
        TYPES = ToFedora::Descriptive::RelatedResource::TYPES.invert.freeze

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          related_items.map do |related_item|
            {}.tap do |item|
              item[:title] = build_titles(related_item)
              item[:contributor] = build_contributors(related_item)
              item[:access] = build_access(related_item)
              item[:form] = build_form(related_item)
              item[:type] = type_for(related_item['type']) if related_item['type']
              item[:displayLabel] = related_item['displayLabel']
            end.compact
          end
        end

        private

        attr_reader :ng_xml

        def build_form(related_item)
          extents = related_item.xpath('mods:physicalDescription/mods:extent', mods: DESC_METADATA_NS)
          return if extents.blank?

          extents.map { |extent| { type: 'extent', value: extent.text } }
        end

        def build_access(related_item)
          urls = related_item.xpath('mods:location/mods:url', mods: DESC_METADATA_NS)
          return if urls.blank?

          { url: urls.map { |url| { value: url.text } } }
        end

        def build_titles(related_item)
          titles = related_item.xpath('mods:titleInfo/mods:title', mods: DESC_METADATA_NS)
          return if titles.blank?

          titles.map { |title| { value: title.text } }
        end

        def build_contributors(related_item)
          names = related_item.xpath('mods:name', mods: DESC_METADATA_NS)
          return if names.blank?

          names.map do |name|
            name_parts = name.xpath('mods:namePart', mods: DESC_METADATA_NS)
            { name: name_parts.map { |part| { value: part.text } } }.tap do |result|
              result[:type] = Contributor::ROLES.fetch(name['type']) if name['type']
            end
          end
        end

        def related_items
          ng_xml.xpath('//mods:mods/mods:relatedItem', mods: DESC_METADATA_NS)
        end

        def type_for(type)
          # This handles a common data error.
          if type.downcase == 'other version'
            Honeybadger.notify('[DATA ERROR] Invalid related resource type (Other version)', { tags: 'data_error' })
            return TYPES['otherVersion']
          end
          TYPES.fetch(type)
        end
      end
    end
  end
end

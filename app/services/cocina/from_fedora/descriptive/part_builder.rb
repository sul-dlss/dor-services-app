# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps parts
      class PartBuilder
        # @param [Nokogiri::XML::Element] part_element
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(part_element:)
          new(part_element: part_element).build
        end

        def initialize(part_element:)
          @part_element = part_element
        end

        def build
          values = []
          values.concat(detail_values)
          values.concat(extent_values)
          values.concat(part_note_value_for(part_element, 'text'))
          values.concat(part_note_value_for(part_element, 'date'))

          return if values.empty?

          {
            type: 'part',
            groupedValue: values
          }
        end

        private

        attr_reader :part_element

        def detail_values
          detail_node = part_element.xpath('mods:detail', mods: DESC_METADATA_NS).first
          return [] unless detail_node

          detail_values = []
          detail_values.concat(part_note_value_for(detail_node, 'number'))
          detail_values.concat(part_note_value_for(detail_node, 'caption'))
          detail_values.concat(part_note_value_for(detail_node, 'title'))
          detail_values.concat(part_note_value_for(detail_node, 'detail type', xpath: '@type')) if detail_values.present?
          detail_values
        end

        def extent_values
          extent_node = part_element.xpath('mods:extent', mods: DESC_METADATA_NS).first
          return [] unless extent_node

          extent_values = []
          extent_values.concat(part_note_value_for(extent_node, 'list'))
          extent_values.concat(part_note_value_for(extent_node, 'extent unit', xpath: '@unit')) if extent_values.present?
          extent_values
        end

        def part_note_value_for(node, type, xpath: nil)
          xpath ||= "mods:#{type}"
          node.xpath(xpath, mods: DESC_METADATA_NS).map do |value_node|
            next nil if value_node.content.blank?

            { type: type, value: value_node.content }
          end.compact
        end
      end
    end
  end
end

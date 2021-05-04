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
          structured_value? ? structured_value : grouped_value
        end

        private

        attr_reader :part_element

        def structured_value?
          part_element.xpath('mods:detail[@type]', mods: DESC_METADATA_NS).size > 1
        end

        def grouped_value
          values = []
          values.concat(detail_values.flatten)
          values.concat(extent_values.flatten)
          values.concat(part_note_value_for(part_element, 'text'))
          values.concat(part_note_value_for(part_element, 'date'))
          values.reject!(&:blank?)

          return if values.empty?

          {
            type: 'part',
            groupedValue: values
          }
        end

        def structured_value
          values = []
          values.concat(detail_values)
          values.concat(extent_values)
          values.concat(part_note_value_for(part_element, 'text'))
          values.concat(part_note_value_for(part_element, 'date'))
          values.reject!(&:blank?)

          return if values.empty?

          {
            type: 'part',
            structuredValue: values.filter_map { |value| structured_value_value_for(value) }
          }
        end

        def structured_value_value_for(value)
          if value.is_a?(Hash)
            value
          elsif value.empty? # else an array
            nil
          else
            {
              groupedValue: value
            }
          end
        end

        def detail_values
          part_element.xpath('mods:detail', mods: DESC_METADATA_NS).filter_map { |detail_node| detail_values_for(detail_node) }
        end

        def detail_values_for(detail_node)
          detail_values = []
          detail_values.concat(part_note_value_for(detail_node, 'number'))
          detail_values.concat(part_note_value_for(detail_node, 'caption'))
          detail_values.concat(part_note_value_for(detail_node, 'title'))
          detail_values.reject!(&:blank?)
          detail_values.concat(part_note_value_for(detail_node, 'detail type', xpath: '@type')) if detail_values.present?
          detail_values
        end

        def extent_values
          part_element.xpath('mods:extent', mods: DESC_METADATA_NS).filter_map { |extent_node| extent_values_for(extent_node) }
        end

        def extent_values_for(extent_node)
          extent_values = []
          extent_values.concat(part_note_value_for(extent_node, 'list'))
          extent_values << pages_for(extent_node)
          extent_values.reject!(&:blank?)
          extent_values.concat(part_note_value_for(extent_node, 'extent unit', xpath: '@unit')) if extent_values.present?
          extent_values
        end

        def pages_for(extent_node)
          values = []
          values << page_value_for(extent_node, 'start')
          values << page_value_for(extent_node, 'end')
          values.compact!

          return nil if values.empty?

          {
            structuredValue: values
          }
        end

        def page_value_for(extent_node, type)
          page_node = extent_node.xpath("mods:#{type}", mods: DESC_METADATA_NS).first
          return nil if page_node.nil?

          {
            value: page_node.content,
            type: type
          }
        end

        def part_note_value_for(node, type, xpath: nil)
          xpath ||= "mods:#{type}"
          node.xpath(xpath, mods: DESC_METADATA_NS).filter_map do |value_node|
            next if value_node.content.blank?

            { type: type, value: value_node.content }
          end
        end
      end
    end
  end
end

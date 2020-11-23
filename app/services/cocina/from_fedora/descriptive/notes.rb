# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps notes
      class Notes
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder: nil)
          new(resource_element: resource_element).build
        end

        def initialize(resource_element:)
          @resource_element = resource_element
        end

        def build
          abstract + notes + table_of_contents
        end

        private

        attr_reader :resource_element

        def abstract
          set = resource_element.xpath('mods:abstract', mods: DESC_METADATA_NS)
          set.map do |node|
            { type: 'summary', value: node.content }.tap do |attributes|
              attributes[:displayLabel] = node[:displayLabel] if node[:displayLabel]
            end
          end
        end

        def notes
          set = resource_element.xpath('mods:note', mods: DESC_METADATA_NS).select { |node| node.text.present? }
          set.map do |node|
            { value: node.text }.tap do |attributes|
              attributes[:type] = node[:type] if node[:type]
              attributes[:displayLabel] = node[:displayLabel] if node[:displayLabel]
            end
          end
        end

        def table_of_contents
          set = resource_element.xpath('mods:tableOfContents', mods: DESC_METADATA_NS)
          set.map do |node|
            { type: 'table of contents' }.tap do |attributes|
              attributes[:displayLabel] = node[:displayLabel] if node[:displayLabel]
              value_parts = node.content.split(' -- ')
              if value_parts.size == 1
                attributes[:value] = node.content
              else
                attributes[:structuredValue] = value_parts.map { |value_part| { value: value_part } }
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS identifer to cocina identifier
      class Identifier
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
          identifiers.map do |id|
            { value: id.text }.tap do |item|
              item[:type] = id['type'].upcase if id['type']
              item[:displayLabel] = id['displayLabel'] if id['displayLabel']
            end
          end
        end

        private

        attr_reader :resource_element

        def identifiers
          resource_element.xpath('mods:identifier', mods: DESC_METADATA_NS)
        end
      end
    end
  end
end

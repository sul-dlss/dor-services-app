# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps titles
      class HydrusDefaultTitleBuilder
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [boolean] require_title raise Cocina::Mapper::MissingTitle if true and title is missing.
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, require_title: nil)
          titles = resource_element.xpath('mods:titleInfo/mods:title[string-length() > 0]', mods: DESC_METADATA_NS)
          return [{ value: 'Hydrus' }] if titles.empty?

          Titles.build(resource_element: resource_element)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps languages
      class Language
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
          resource_element.xpath('mods:language', mods: DESC_METADATA_NS).map do |lang_node|
            Cocina::FromFedora::Descriptive::LanguageTerm.build(language_element: lang_node)
          end
        end

        private

        attr_reader :resource_element
      end
    end
  end
end

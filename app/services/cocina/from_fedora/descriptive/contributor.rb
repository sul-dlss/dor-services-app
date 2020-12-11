# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps contributors
      class Contributor
        # key: MODS, value: cocina
        ROLES = {
          'personal' => 'person',
          'corporate' => 'organization',
          'family' => 'family',
          'conference' => 'conference'
        }.freeze

        NAME_PART = {
          'family' => 'surname',
          'given' => 'forename',
          'termsOfAddress' => 'term of address',
          'date' => 'life dates'
        }.freeze

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
          grouped_altrepgroup_name_nodes, other_name_nodes = AltRepGroup.split(nodes: resource_element.xpath('mods:name', mods: DESC_METADATA_NS))
          grouped_altrepgroup_name_nodes.map { |name_nodes| build_name_nodes(name_nodes) } + \
            other_name_nodes.map { |name_node| build_name_nodes([name_node]) }
        end

        private

        attr_reader :resource_element

        def build_name_nodes(name_nodes)
          name_nodes.each { |name_node| Honeybadger.notify('[DATA ERROR] name type attribute is set to ""', { tags: 'data_error' }) if name_node['type'] == '' }
          NameBuilder.build(name_elements: name_nodes)
        end
      end
    end
  end
end

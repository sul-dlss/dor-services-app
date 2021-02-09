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
        def self.build(resource_element:, descriptive_builder:)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @notifier = descriptive_builder.notifier
        end

        def build
          grouped_altrepgroup_name_nodes, other_name_nodes = AltRepGroup.split(nodes: deduped_name_nodes)
          contributors = grouped_altrepgroup_name_nodes.map { |name_nodes| build_name_nodes(name_nodes) } + \
                         other_name_nodes.map { |name_node| build_name_nodes([name_node]) }
          adjust_primary(contributors.compact).presence
        end

        private

        attr_reader :resource_element, :notifier

        def deduped_name_nodes
          name_nodes = resource_element.xpath('mods:name', mods: DESC_METADATA_NS)
          uniq_name_nodes = name_nodes.uniq(&:to_s)

          notifier.warn('Duplicate name entry') if name_nodes.size != uniq_name_nodes.size
          uniq_name_nodes
        end

        def build_name_nodes(name_nodes)
          name_nodes.each { |name_node| notifier.warn('Missing or empty name type attribute') if name_node['type'].blank? && name_node['xlink:href'].blank? }
          NameBuilder.build(name_elements: name_nodes, notifier: notifier).presence
        end

        def adjust_primary(contributors)
          Primary.adjust(contributors, 'name', notifier)
          contributors.each do |contributor|
            contributor[:name].each do |name|
              Primary.adjust(name[:parallelValue], 'name', notifier) if name[:parallelValue]
            end
          end
          contributors
        end
      end
    end
  end
end

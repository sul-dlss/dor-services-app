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
        # @param [String] purl
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:, purl: nil)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @notifier = descriptive_builder.notifier
        end

        def build
          grouped_altrepgroup_name_nodes, other_name_nodes = AltRepGroup.split(nodes: deduped_name_nodes)
          check_altrepgroup_type_inconsistency(grouped_altrepgroup_name_nodes)
          contributors = grouped_altrepgroup_name_nodes.map { |name_nodes| build_name_nodes(name_nodes) } + \
                         other_name_nodes.map { |name_node| build_name_nodes([name_node]) }
          adjust_primary(contributors.compact).presence
        end

        private

        attr_reader :resource_element, :notifier

        def deduped_name_nodes
          # In addition, to plain-old dupes, need to get rid of names that are dupes with nameTitleGroups.
          # Need to retain nameTitleGroups, so sorting so that first. (Uniq takes first.)
          # When comparing, need to remove usage and nameTitleGroup.
          name_nodes = resource_element.xpath('mods:name', mods: DESC_METADATA_NS)
          nametitle_nodes, other_nodes = name_nodes.partition { |name_node| name_node['nameTitleGroup'] }
          ordered_name_nodes = nametitle_nodes + other_nodes
          uniq_name_nodes = ordered_name_nodes.uniq do |name_node|
            dup_name_node = name_node.dup
            dup_name_node.delete('usage')
            dup_name_node.delete('nameTitleGroup')
            dup_name_node.to_s
          end

          notifier.warn('Duplicate name entry') if name_nodes.size != uniq_name_nodes.size

          uniq_name_nodes
        end

        def check_altrepgroup_type_inconsistency(grouped_altrepgroup_name_nodes)
          grouped_altrepgroup_name_nodes.each do |altrepgroup_name_nodes|
            altrepgroup_name_types = altrepgroup_name_nodes.group_by { |name_node| name_node['type'] }.keys
            next unless altrepgroup_name_types.size > 1

            notifier.error('Multiple types for same altRepGroup', { types: altrepgroup_name_types })
          end
        end

        def build_name_nodes(name_nodes)
          name_nodes.each do |name_node|
            notifier.warn('Missing or empty name type attribute') if missing_name_type?(name_node)
          end
          NameBuilder.build(name_elements: name_nodes, notifier: notifier).presence
        end

        def missing_name_type?(name_node)
          name_node['type'].blank? &&
            name_node['xlink:href'].blank? &&
            name_node.xpath('mods:etal', mods: DESC_METADATA_NS).empty? &&
            name_node.ancestors('relatedItem').empty? &&
            name_node['valueURI'].blank? &&
            name_node.xpath('mods:role/mods:roleTerm[text() = "event"]', mods: DESC_METADATA_NS).empty?
        end

        def adjust_primary(contributors)
          Primary.adjust(contributors, 'name', notifier)
          contributors.each do |contributor|
            Array(contributor[:name]).each do |name|
              Primary.adjust(name[:parallelValue], 'name', notifier) if name[:parallelValue]
            end
          end
          contributors
        end
      end
    end
  end
end

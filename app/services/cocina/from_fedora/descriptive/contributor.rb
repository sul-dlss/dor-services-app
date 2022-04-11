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
          contrib_level_type_and_status(contributors)
          adjust_primary(contributors.compact).presence
        end

        private

        attr_reader :resource_element, :notifier

        def deduped_name_nodes
          # In addition, to plain-old dupes, need to get rid of names that are dupes where
          #   e.g., one has a nameTitleGroup and one does not
          # Need to retain nameTitleGroups, so sorting so those first. (Array.uniq takes first.)
          name_nodes = resource_element.xpath('mods:name', mods: DESC_METADATA_NS)
          nametitle_nodes, other_nodes = name_nodes.partition { |name_node| name_node['nameTitleGroup'] }
          ordered_name_nodes = nametitle_nodes + other_nodes
          uniq_name_nodes = uniq_name_nodes(ordered_name_nodes)

          notifier.warn('Duplicate name entry') if name_nodes.size != uniq_name_nodes.size

          include_all_uniq_roles(uniq_name_nodes)
        end

        # uniq retains the first value, so sort input with that in mind.
        # @param [Array<Nokogiri::XML::Node>]
        # @return [Array<Nokogiri::XML::Node>] (yes, Johnny, this returns array of nodes, not comparitors)
        def uniq_name_nodes(name_nodes)
          name_nodes.uniq do |name_node|
            name_node_comparitor(name_node)
          end
        end

        # remove usage and nameTitleGroup attributes and role nodes for uniqueness comparison
        # @return [String] a string to be used by Array.uniq for .eql? comparisons
        def name_node_comparitor(name_node)
          dup_name_node = name_node.dup
          dup_name_node.delete('usage')
          dup_name_node.delete('nameTitleGroup')
          dup_name_node.xpath('mods:role', mods: DESC_METADATA_NS).each(&:unlink)
          dup_name_node.to_s.strip.gsub(/\s+/, ' ')
        end

        # ensure all roles for each uniq name node are present
        # @return [Array<Nokogiri::XML::Node] the uniq name nodes with all roles present
        def include_all_uniq_roles(uniq_name_nodes)
          names_to_roles = name_comparitor_2_role_nodes # compute this once
          uniq_name_nodes.each do |uniq_name_node|
            role_nodes = names_to_roles[name_node_comparitor(uniq_name_node)]
            next if role_nodes.blank?

            uniq_name_node.xpath('mods:role', mods: DESC_METADATA_NS).each(&:unlink)
            role_nodes.each { |role_node| uniq_name_node.add_child(role_node) }
          end
          uniq_name_nodes
        end

        # @return [Hash<String, Array[Nokogiri::XML::Node]] key is the string comparitor for a name node;
        #   value is an Array of uniq role nodes
        def name_comparitor_2_role_nodes
          result = {}

          # we must do this outside the loop in case of duplicate name nodes
          all_role_nodes = resource_element.xpath('mods:name/mods:role', mods: DESC_METADATA_NS)
          all_role_nodes.each do |role_node|
            name_comparitor = name_node_comparitor(role_node.parent)
            result[name_comparitor] = if result[name_comparitor]
                                        result[name_comparitor] << role_node
                                      else
                                        [role_node]
                                      end
          end

          result.each { |_k, role_nodes| role_nodes.uniq! { |role_node| name_node_comparitor(role_node) } }
        end

        def check_altrepgroup_type_inconsistency(grouped_altrepgroup_name_nodes)
          grouped_altrepgroup_name_nodes.each do |altrepgroup_name_nodes|
            altrepgroup_name_types = altrepgroup_name_nodes.group_by { |name_node| name_node['type'] }.keys
            next unless altrepgroup_name_types.size > 1

            notifier.error('Multiple types for same altRepGroup', { types: altrepgroup_name_types })
          end
        end

        def build_name_nodes(name_nodes)
          NameBuilder.build(name_elements: name_nodes, notifier: notifier).presence
        end

        def adjust_primary(contributors)
          Primary.adjust(contributors, 'contributor', notifier)
          contributors.each do |contributor|
            Array(contributor[:name]).each do |name|
              Primary.adjust(name[:parallelValue], 'name', notifier) if name[:parallelValue]
            end
          end
          contributors
        end

        # 'type' and 'status' are generated in name_builder on the name level object,
        #   but we want them at the contributor level object.
        def contrib_level_type_and_status(contributors)
          contributors.each do |contributor|
            next if contributor.blank?

            Array(contributor[:name]).each do |name|
              if name[:status] == 'primary'
                contributor[:status] = 'primary'
                name.delete(:status)
              end
              if name[:type].present? && ROLES.value?(name[:type])
                contributor[:type] = name[:type].presence
                name.delete(:type)
              end
            end
          end
        end
      end
    end
  end
end

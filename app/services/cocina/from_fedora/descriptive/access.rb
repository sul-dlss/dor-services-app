# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps access conditions
      class Access
        ACCESS_CONDITION_TYPES = {
          'restriction on access' => 'access restriction',
          'restrictionOnAccess' => 'access restriction',
          'useAndReproduction' => 'use and reproduction'
        }.freeze

        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @param [String] purl
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:, purl: nil)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder, purl: purl).build
        end

        def initialize(resource_element:, descriptive_builder:, purl:)
          @resource_element = resource_element
          @notifier = descriptive_builder.notifier
          @purl = purl
        end

        def build
          {}.tap do |access|
            physical_locations = physical_location + shelf_location + xlink_location
            access[:physicalLocation] = physical_locations.presence
            access[:digitalLocation] = digital_location.presence
            access[:accessContact] = access_contact.presence
            access[:url] = url.presence
            access[:note] = (note + purl_note).presence
            # Without the count check, this node winds up all over the damn place and breaks dozens of tests
            access[:digitalRepository] = [{ value: 'Stanford Digital Repository' }] if purl
          end.compact
        end

        private

        attr_reader :resource_element, :notifier, :add_sdr, :purl

        # Hydrus is known to create location nodes with no children.
        def location_nodes
          resource_element.xpath('mods:location[*]', mods: DESC_METADATA_NS)
        end

        def physical_location
          descriptive_value_for(resource_element.xpath("mods:location/mods:physicalLocation[not(@type='repository')][not(@type='discovery')]", mods: DESC_METADATA_NS))
        end

        def digital_location
          descriptive_value_for(resource_element.xpath("mods:location/mods:physicalLocation[(@type='discovery')]", mods: DESC_METADATA_NS))
        end

        def xlink_location
          resource_element.xpath('mods:location/mods:physicalLocation[@xlink:href]', mods: DESC_METADATA_NS, xlink: XLINK_NS).map do |node|
            {
              valueAt: node['xlink:href']
            }
          end
        end

        def access_contact
          descriptive_value_for(resource_element.xpath("mods:location/mods:physicalLocation[@type='repository']", mods: DESC_METADATA_NS)) +
            descriptive_value_for(resource_element.xpath("mods:note[@type='contact']", mods: DESC_METADATA_NS), type: 'email')
        end

        def shelf_location
          resource_element.xpath('mods:location/mods:shelfLocator', mods: DESC_METADATA_NS).filter_map do |shelf_locator_elem|
            next if shelf_locator_elem.content.blank?

            {
              value: shelf_locator_elem.content,
              type: 'shelf locator'
            }
          end
        end

        def url
          url_nodes.filter_map do |url_node|
            {
              value: url_node.text.presence,
              displayLabel: url_node[:displayLabel]
            }.tap do |attrs|
              attrs[:status] = 'primary' if url_node == primary_url_node
              attrs[:note] = [{ value: url_node[:note] }] if url_node[:note]
            end.compact.presence
          end
        end

        def primary_url_node
          all_primary_purl_nodes.first || all_primary_url_nodes.first || this_purl_node || all_purl_nodes.first
        end

        def this_purl_node
          purl ? all_purl_nodes.find { |purl_node| purl_node.content == purl } : nil
        end

        def all_primary_url_nodes
          @all_primary_url_nodes ||= all_url_nodes.select { |url_node| url_node[:usage] == 'primary display' }
        end

        def all_primary_purl_nodes
          @all_primary_purl_nodes ||= all_purl_nodes.select { |purl_node| purl_node[:usage] == 'primary display' }
        end

        def all_purl_nodes
          @all_purl_nodes ||= all_url_nodes.select { |url_node| Purl.purl?(url_node) }
        end

        def all_url_nodes
          @all_url_nodes ||= resource_element.xpath('mods:location/mods:url', mods: DESC_METADATA_NS)
        end

        def primary_purl_node
          @primary_purl_node ||= Purl.primary_purl_node(resource_element, purl)
        end

        def url_nodes
          @url_nodes ||= all_url_nodes.reject { |url_node| Purl.purl?(url_node) }
        end

        def purl_note
          return [] unless primary_purl_node

          Purl.purl_note(primary_purl_node)
        end

        def note
          resource_element.xpath('mods:accessCondition', mods: DESC_METADATA_NS).map do |access_elem|
            {
              value: access_elem.text.presence,
              type: ACCESS_CONDITION_TYPES.fetch(access_elem['type'], access_elem['type']),
              displayLabel: access_elem['displayLabel'],
              valueAt: access_elem['xlink:href']
            }.compact
          end
        end

        def descriptive_value_for(nodes, type: nil)
          nodes.filter_map do |node|
            next nil if node.text.blank?

            {}.tap do |attrs|
              if %w[marcorg oclcorg].include?(node[:authority])
                attrs[:code] = node.text
              else
                attrs[:value] = node.text
              end
              attrs[:uri] = ValueURI.sniff(node[:valueURI], notifier)
              source = {
                code: Authority.normalize_code(node[:authority], notifier),
                uri: Authority.normalize_uri(node[:authorityURI])
              }.compact
              attrs[:source] = source unless source.empty?
              attrs[:type] = type || node[:type]
              attrs[:displayLabel] = node[:displayLabel]
              attrs[:valueLanguage] = LanguageScript.build(node: node)
            end.compact
          end
        end
      end
    end
  end
end

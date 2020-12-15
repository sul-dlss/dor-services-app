# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps locations
      class Location
        PURL_REGEX = %r{^https?://purl.stanford.edu/}.freeze

        ACCESS_CONDITION_TYPES = {
          'restriction on access' => 'access restriction',
          'restrictionOnAccess' => 'access restriction',
          'useAndReproduction' => 'use and reproduction'
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
          {}.tap do |access|
            physical_locations = physical_location + shelf_location
            access[:physicalLocation] = physical_locations if physical_locations.present?
            access[:digitalLocation] = digital_location if digital_location.present?
            access[:accessContact] = access_contact if access_contact.present?
            access[:url] = url if url.present?
            notes = note + purl_note
            access[:note] = notes if notes.present?
            # Without the count check, this node winds up all over the damn place and breaks dozens of tests
            access[:digitalRepository] = [{ value: 'Stanford Digital Repository' }] if location_nodes_count.positive?
          end
        end

        private

        attr_reader :resource_element

        def location_nodes_count
          resource_element.xpath('mods:location', mods: DESC_METADATA_NS).count
        end

        def physical_location
          descriptive_value_for(resource_element.xpath("mods:location/mods:physicalLocation[not(@type='repository')][not(@type='discovery')]", mods: DESC_METADATA_NS))
        end

        def digital_location
          descriptive_value_for(resource_element.xpath("mods:location/mods:physicalLocation[(@type='discovery')]", mods: DESC_METADATA_NS))
        end

        def access_contact
          @access_contact ||= descriptive_value_for(resource_element.xpath("mods:location/mods:physicalLocation[@type='repository']", mods: DESC_METADATA_NS))
        end

        def shelf_location
          resource_element.xpath('mods:location/mods:shelfLocator', mods: DESC_METADATA_NS).map do |shelf_locator_elem|
            {
              value: shelf_locator_elem.text,
              type: 'shelf locator'
            }
          end
        end

        def url
          @url ||= url_nodes.map do |url_node|
            {
              value: url_node.text,
              displayLabel: url_node[:displayLabel]
            }.tap do |attrs|
              attrs[:status] = 'primary' if url_node[:usage] == 'primary display'
              attrs[:note] = [{ value: url_node[:note] }] if url_node[:note]
            end.compact
          end
        end

        def primary_purl_node
          @primary_purl_node ||= all_purl_nodes.size == 1 ? all_purl_nodes.first : all_purl_nodes.find { |purl_node| purl_node[:usage] == 'primary display' }
        end

        def all_purl_nodes
          @all_purl_nodes ||= all_url_nodes.select { |url_node| PURL_REGEX.match(url_node.text) }
        end

        def all_url_nodes
          @all_url_nodes ||= resource_element.xpath('mods:location/mods:url', mods: DESC_METADATA_NS)
        end

        def url_nodes
          @url_nodes ||= all_url_nodes.reject { |url_node| url_node == primary_purl_node }
        end

        def purl_note
          @purl_note ||= if primary_purl_node && primary_purl_node[:note]
                           [{
                             type: 'purl access',
                             value: primary_purl_node[:note]
                           }]
                         else
                           []
                         end
        end

        def note
          @note ||= resource_element.xpath('mods:accessCondition', mods: DESC_METADATA_NS).map do |access_elem|
            {
              value: access_elem.text,
              type: ACCESS_CONDITION_TYPES.fetch(access_elem['type'], access_elem['type'])
            }
          end
        end

        def descriptive_value_for(nodes)
          nodes.map do |node|
            {}.tap do |attrs|
              if node[:authority] && !node[:valueURI]
                attrs[:code] = node.text
              else
                attrs[:value] = node.text
              end
              attrs[:uri] = ValueURI.sniff(node[:valueURI])
              source = {
                code: Authority.normalize_code(node[:authority]),
                uri: Authority.normalize_uri(node[:authorityURI])
              }.compact
              attrs[:source] = source unless source.empty?
              attrs[:type] = node[:type]
              attrs[:displayLabel] = node[:displayLabel]
              attrs[:valueLanguage] = LanguageScript.build(node: node)
            end.compact
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps locations
      class Location
        PURL_REGEX = %r{^https?://purl.stanford.edu/}.freeze

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
            access[:accessContact] = access_contact if access_contact.present?
            access[:url] = url if url.present?
          end
        end

        private

        attr_reader :resource_element

        def physical_location
          descriptive_value_for(resource_element.xpath("mods:location/mods:physicalLocation[not(@type='repository')]", mods: DESC_METADATA_NS))
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
          @url ||= resource_element.xpath('mods:location/mods:url', mods: DESC_METADATA_NS).map do |url_elem|
            url_value = url_elem.text
            next nil if PURL_REGEX.match(url_value)

            { value: url_value }.tap do |attrs|
              attrs[:status] = 'primary' if url_elem[:usage] == 'primary display'
              attrs[:displayLabel] = url_elem[:displayLabel] if url_elem[:displayLabel]
              attrs[:note] = [{ value: url_elem[:note] }] if url_elem[:note]
            end
          end.compact
        end

        def descriptive_value_for(nodes)
          nodes.map do |node|
            {}.tap do |attrs|
              if node[:authority] && !node[:valueURI]
                attrs[:code] = node.text
              else
                attrs[:value] = node.text
              end
              attrs[:uri] = node[:valueURI]
              source = { code: node[:authority], uri: AuthorityUri.normalize(node[:authorityURI]) }.compact
              attrs[:source] = source unless source.empty?
              attrs[:type] = node[:type]
              value_language = LanguageScript.build(node: node)
              attrs[:valueLanguage] = value_language if value_language
            end.compact
          end
        end
      end
    end
  end
end

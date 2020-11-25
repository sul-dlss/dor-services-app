# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps location from cocina to MODS XML
      class Location
        # @params [Nokogiri::XML::Builder] xml
        # @params [Cocina::Models::Access] access
        # @params [string] purl
        def self.write(xml:, access:, purl:)
          new(xml: xml, access: access, purl: purl).write
        end

        def initialize(xml:, access:, purl:)
          @xml = xml
          @access = access
          @purl = purl
        end

        def write
          return if access.nil? && purl.nil?

          xml.location do
            if access.present?
              write_physical_locations
              write_shelf_locators
              write_urls
            end
            write_purl if purl
          end
        end

        private

        attr_reader :xml, :access, :purl

        def write_physical_locations
          Array(access.physicalLocation).reject { |physical_location| shelf_locator?(physical_location) }.each do |physical_location|
            xml.physicalLocation physical_location.value || physical_location.code, with_uri_info(physical_location, {})
          end

          Array(access.accessContact).each do |access_contact|
            xml.physicalLocation access_contact.value, with_uri_info(access_contact, { type: 'repository' })
          end
        end

        def write_shelf_locators
          Array(access.physicalLocation).select { |physical_location| shelf_locator?(physical_location) }.each do |physical_location|
            xml.shelfLocator physical_location.value
          end
        end

        def write_urls
          Array(access.url).each do |url|
            url_attrs = {}.tap do |attrs|
              attrs[:usage] = 'primary display' if url.status == 'primary'
              attrs[:displayLabel] = url.displayLabel
              attrs[:note] = url.note.first.value unless url.note.nil?
            end.compact
            xml.url url.value, url_attrs
          end
        end

        def write_purl
          xml.url purl, { usage: 'primary display' }
        end

        def with_uri_info(cocina, xml_attrs)
          xml_attrs[:valueURI] = cocina.uri
          xml_attrs[:authorityURI] = cocina.source&.uri
          xml_attrs[:authority] = cocina.source&.code
          xml_attrs.compact
        end

        def shelf_locator?(physical_location)
          physical_location.type == 'shelf locator'
        end
      end
    end
  end
end

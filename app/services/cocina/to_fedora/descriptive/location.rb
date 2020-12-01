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
          write_purl unless purl.nil?
          return if access.nil?

          write_access_conditions if access

          Array(access.url).each do |url|
            xml.location do
              write_url(url)
            end
          end

          if access.physicalLocation
            xml.location do
              write_physical_locations
              write_shelf_locators
            end
          end

          return unless access.accessContact

          xml.location do
            write_access_contact_locations
          end
        end

        private

        attr_reader :xml, :access, :purl

        def write_physical_locations
          Array(access.physicalLocation).reject { |physical_location| shelf_locator?(physical_location) }.each do |physical_location|
            xml.physicalLocation physical_location.value || physical_location.code, descriptive_attrs(physical_location)
          end
        end

        def write_access_contact_locations
          Array(access.accessContact).each do |access_contact|
            xml.physicalLocation access_contact.value, { type: 'repository' }.merge(descriptive_attrs(access_contact))
          end
        end

        def write_shelf_locators
          Array(access.physicalLocation).select { |physical_location| shelf_locator?(physical_location) }.each do |physical_location|
            xml.shelfLocator physical_location.value
          end
        end

        def write_url(url)
          url_attrs = {}.tap do |attrs|
            attrs[:usage] = 'primary display' if url.status == 'primary'
            attrs[:displayLabel] = url.displayLabel
            attrs[:note] = url.note.first.value unless url.note.nil?
          end.compact
          xml.url url.value, url_attrs
        end

        def write_purl
          xml.url purl, { usage: 'primary display' }
        end

        def descriptive_attrs(cocina)
          {}.tap do |attrs|
            attrs[:valueURI] = cocina.uri
            attrs[:authorityURI] = cocina.source&.uri
            attrs[:authority] = cocina.source&.code
            attrs[:script] = cocina.valueLanguage&.valueScript&.code
            attrs[:lang] = cocina.valueLanguage&.code
          end.compact
        end

        def shelf_locator?(physical_location)
          physical_location.type == 'shelf locator'
        end

        def write_access_conditions
          Array(access.note).each do |note|
            type = note.type == 'access restriction' ? 'restriction on access' : note.type
            xml.accessCondition note.value, type: type
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps the Access subschema from cocina to MODS XML
      class Access
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

          write_physical_locations
          write_digital_locations
          write_shelf_locators
          write_access_contact_locations
        end

        private

        attr_reader :xml, :access, :purl

        def write_physical_locations
          Array(access.physicalLocation).reject { |physical_location| shelf_locator?(physical_location) }.each do |physical_location|
            xml.location do
              xml.physicalLocation physical_location.value || physical_location.code, descriptive_attrs(physical_location)
            end
          end
        end

        def write_digital_locations
          Array(access.digitalLocation).select { |digital_location| digital_location.type == 'discovery' }.each do |digital_location|
            xml.location do
              xml.physicalLocation digital_location.value || digital_location.code, descriptive_attrs(digital_location)
            end
          end
        end

        def write_access_contact_locations
          Array(access.accessContact).each do |access_contact|
            if access_contact.type == 'email'
              xml.note access_contact.value, descriptive_attrs(access_contact).merge({ type: 'contact' })
            else
              xml.location do
                xml.physicalLocation access_contact.value || access_contact.code, { type: 'repository' }.merge(descriptive_attrs(access_contact))
              end
            end
          end
        end

        def write_shelf_locators
          Array(access.physicalLocation).select { |physical_location| shelf_locator?(physical_location) }.each do |physical_location|
            xml.location do
              xml.shelfLocator physical_location.value
            end
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

        def primary_url_is_not_purl?
          Array(access&.url).any? { |url| url.status == 'primary' }
        end

        def write_purl
          purl_attrs = {}.tap do |attrs|
            attrs[:note] = find_note_value(nil)
            attrs[:usage] = 'primary display' unless primary_url_is_not_purl?
            attrs[:displayLabel] = find_note_value('display label')
          end.compact

          xml.location do
            xml.url purl, purl_attrs
          end
        end

        def find_note_value(note_type)
          Array(access.note).find do |note|
            note.type == note_type && purl_note?(note)
          end&.value
        end

        def descriptive_attrs(cocina)
          {
            valueURI: cocina.uri,
            authorityURI: cocina.source&.uri,
            authority: cocina.source&.code,
            script: cocina.valueLanguage&.valueScript&.code,
            lang: cocina.valueLanguage&.code,
            type: cocina.type,
            displayLabel: cocina.displayLabel,
            'xlink:href' => cocina.valueAt
          }.compact
        end

        def shelf_locator?(physical_location)
          physical_location.type == 'shelf locator'
        end

        def write_access_conditions
          Array(access.note).reject { |note| purl_note?(note) }.each do |note|
            attributes = {
              type: note.type == 'access restriction' ? 'restriction on access' : note.type,
              displayLabel: note.displayLabel,
              'xlink:href' => note.valueAt
            }.compact
            xml.accessCondition note.value, attributes
          end
        end

        def purl_note?(note)
          Array(note.appliesTo).any? { |applies_to| applies_to.value == 'purl' }
        end
      end
    end
  end
end

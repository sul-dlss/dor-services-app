# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps originInfo to cocina events
      class Event
        ORIGININFO_XPATH = '/mods:mods/mods:originInfo'

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          [].tap do |events|
            origin_info.each do |origin|
              date_created = origin.xpath('mods:dateCreated', mods: DESC_METADATA_NS)
              events << build_event('creation', date_created) if date_created.present?

              date_issued = origin.xpath('mods:dateIssued', mods: DESC_METADATA_NS)
              events << build_event('publication', date_issued) if date_issued.present?
            end
          end
        end

        private

        attr_reader :ng_xml

        def build_event(type, node_set)
          node = node_set.first
          date = { value: node.text }
          date[:encoding] = { code: node['encoding'] } if node['encoding']
          { type: type, date: [date] }
        end

        def origin_info
          @origin_info ||= ng_xml.xpath(ORIGININFO_XPATH, mods: DESC_METADATA_NS)
        end
      end
    end
  end
end

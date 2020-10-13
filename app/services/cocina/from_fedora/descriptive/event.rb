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
          origin_info.flat_map do |origin|
            events = build_events_for_origin_info(origin)

            events = [{}] if events.empty?
            place = origin.xpath('mods:place', mods: DESC_METADATA_NS)
            add_place_info(events.last, place) if place.present?
            events
          end
        end

        private

        attr_reader :ng_xml

        def build_events_for_origin_info(origin)
          [].tap do |events|
            date_created = origin.xpath('mods:dateCreated', mods: DESC_METADATA_NS)
            events << build_event('creation', date_created) if date_created.present?

            date_issued = origin.xpath('mods:dateIssued', mods: DESC_METADATA_NS)
            events << build_event('publication', date_issued) if date_issued.present?

            copyright_date = origin.xpath('mods:copyrightDate', mods: DESC_METADATA_NS)
            events << build_event('copyright', copyright_date) if copyright_date.present?

            date_captured = origin.xpath('mods:dateCaptured', mods: DESC_METADATA_NS)
            events << build_event('capture', date_captured) if date_captured.present?

            date_other = origin.xpath('mods:dateOther', mods: DESC_METADATA_NS)
            events << build_event(nil, date_other) if date_other.present?
          end
        end

        def add_place_info(event, place_set)
          event[:location] = place_set.map do |place|
            place_term = place.xpath('mods:placeTerm', mods: DESC_METADATA_NS).first
            {
              value: place_term.text,
              uri: place['valueURI'],
              source: {
                code: place['authority'],
                uri: place['authorityURI']
              }
            }
          end
        end

        def build_event(type, node_set)
          points = node_set.select { |node| node['point'] }
          dates = points.size == 1 ? [build_date(type, points.first)] : build_structured_date(type, points)
          node_set.reject { |node| node['point'] }.each do |node|
            dates << build_date(type, node)
          end

          { date: dates }.tap do |event|
            event[:type] = type if type
          end
        end

        def build_structured_date(type, node_set)
          return [] if node_set.blank?

          dates = node_set.map { |node| build_date(type, node) }
          [{ structuredValue: dates }]
        end

        def build_date(type, node)
          {}.tap do |date|
            date[:value] = node.text
            date[:qualifier] = node[:qualifier] if node[:qualifier]
            date[:encoding] = { code: node['encoding'] } if node['encoding']
            date[:status] = 'primary' if node['keyDate']
            date[:note] = [{ value: node['type'], type: 'date type' }] unless type
            date[:type] = node['point'] if node['point']
          end
        end

        def origin_info
          @origin_info ||= ng_xml.xpath(ORIGININFO_XPATH, mods: DESC_METADATA_NS)
        end
      end
    end
  end
end

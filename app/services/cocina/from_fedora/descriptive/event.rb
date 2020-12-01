# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps originInfo to cocina events
      # rubocop:disable Metrics/ClassLength
      class Event
        ORIGININFO_XPATH = 'mods:originInfo'

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
          origin_info.flat_map do |origin|
            events = build_events_for_origin_info(origin, origin[:displayLabel])

            events = [{}] if events.empty?

            place = origin.xpath('mods:place', mods: DESC_METADATA_NS)
            add_place_info(events.last, place) if place.present?

            issuance = origin.xpath('mods:issuance', mods: DESC_METADATA_NS)
            frequency = origin.xpath('mods:frequency', mods: DESC_METADATA_NS)
            edition = origin.xpath('mods:edition', mods: DESC_METADATA_NS)
            publisher = origin.xpath('mods:publisher', mods: DESC_METADATA_NS)
            if issuance.present? || frequency.present? || edition.present? || publisher.present?
              publication_event = find_or_create_publication_event(events)
              add_issuance_info(publication_event, issuance)
              add_frequency_info(publication_event, frequency)
              add_edition_info(publication_event, edition)
              add_publisher_info(publication_event, publisher)
            end
            events.reject(&:blank?)
          end
        end

        private

        attr_reader :resource_element

        def find_or_create_publication_event(events)
          publication_event = events.find { |e| e[:type] == 'publication' }
          return publication_event if publication_event

          { type: 'publication' }.tap do |event|
            events << event
          end
        end

        def build_events_for_origin_info(origin, display_label)
          [].tap do |events|
            date_created = origin.xpath('mods:dateCreated', mods: DESC_METADATA_NS)
            events << build_event('creation', date_created, display_label) if date_created.present?

            date_issued = origin.xpath('mods:dateIssued', mods: DESC_METADATA_NS)
            events << build_event('publication', date_issued, display_label) if date_issued.present?

            copyright_date = origin.xpath('mods:copyrightDate', mods: DESC_METADATA_NS)
            events << build_event('copyright', copyright_date, display_label) if copyright_date.present?

            date_captured = origin.xpath('mods:dateCaptured', mods: DESC_METADATA_NS)
            events << build_event('capture', date_captured, display_label) if date_captured.present?

            date_other = origin.xpath('mods:dateOther', mods: DESC_METADATA_NS)
            events << build_event(date_other_event_type(origin), date_other, display_label) if date_other.present?

            has_date = [date_created, date_issued, copyright_date, date_captured, date_other].flatten.present?
            events << build_event('creation', [], display_label) if origin[:eventType] == 'production' && !has_date
          end
        end

        def add_place_info(event, place_set)
          event[:location] = place_set.map do |place|
            text_place_term = place.xpath("mods:placeTerm[@type='text']", mods: DESC_METADATA_NS).first
            code_place_term = place.xpath("mods:placeTerm[@type='code']", mods: DESC_METADATA_NS).first

            return nil unless text_place_term || code_place_term

            location = with_uri_info({}, text_place_term || code_place_term)

            location[:code] = code_place_term.text if code_place_term
            location[:value] = text_place_term.text if text_place_term

            location
          end.compact
        end

        def with_uri_info(cocina, xml_node)
          cocina[:uri] = xml_node['valueURI'] if xml_node['valueURI']
          if xml_node['authority']
            cocina[:source] = {
              code: xml_node['authority'],
              uri: AuthorityUri.normalize(xml_node['authorityURI'])
            }.compact
          end
          cocina
        end

        def add_issuance_info(event, set)
          return if set.empty?

          event[:note] ||= []
          set.each do |issuance|
            event[:note] << {
              source: { value: 'MODS issuance terms' },
              type: 'issuance',
              value: issuance.text
            }
          end
        end

        def add_frequency_info(event, set)
          return if set.empty?

          event[:note] ||= []
          set.each do |frequency|
            note = {
              type: 'frequency',
              value: frequency.text
            }
            event[:note] << with_uri_info(note, frequency)
          end
        end

        def add_edition_info(event, set)
          return if set.empty?

          event[:note] ||= []
          set.each do |edition|
            event[:note] << {
              type: 'edition',
              value: edition.text
            }
          end
        end

        def add_publisher_info(event, set)
          return if set.empty?

          event[:contributor] ||= []
          set.each do |publisher|
            event[:contributor] << {
              name: [{ value: publisher.text }],
              type: 'organization',
              role: [
                {
                  "value": 'publisher',
                  "code": 'pbl',
                  "uri": 'http://id.loc.gov/vocabulary/relators/pbl',
                  "source": {
                    "code": 'marcrelator',
                    "uri": 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          end
        end

        def build_event(type, node_set, display_label = nil)
          points = node_set.select { |node| node['point'] }
          dates = points.size == 1 ? [build_date(type, points.first)] : build_structured_date(type, points)
          node_set.reject { |node| node['point'] }.each do |node|
            dates << build_date(type, node)
          end

          {}.tap do |event|
            event[:date] = dates unless dates.empty?
            event[:displayLabel] = display_label if display_label
            event[:type] = type if type
            Honeybadger.notify('[DATA ERROR] originInfo/dateOther missing eventType', { tags: 'data_error' }) unless event[:type]
          end
        end

        def build_structured_date(type, node_set)
          return [] if node_set.blank?

          dates = node_set.map { |node| build_date(type, node) }
          [{ structuredValue: dates }]
        end

        def build_date(event_type, node)
          {}.tap do |date|
            date[:value] = node.text
            date[:qualifier] = node[:qualifier] if node[:qualifier]
            date[:encoding] = { code: node['encoding'] } if node['encoding']
            date[:status] = 'primary' if node['keyDate']
            if (!event_type || event_type == 'creation') && (node['type'] || node['calendar'])
              date[:note] = [
                {
                  value: (node['type'] || node['calendar']),
                  type: node['type'] ? 'date type' : 'calendar'
                }
              ]
            end
            date[:type] = node['point'] if node['point']
          end
        end

        def date_other_event_type(origin)
          return 'creation' if origin['eventType'] == 'production'

          origin['eventType']
        end

        def origin_info
          @origin_info ||= resource_element.xpath(ORIGININFO_XPATH, mods: DESC_METADATA_NS)
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end

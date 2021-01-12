# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps originInfo to cocina events
      # rubocop:disable Metrics/ClassLength
      class Event
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @notifier = descriptive_builder.notifier
        end

        def build
          altrepgroup_origin_info_nodes, other_origin_info_nodes = AltRepGroup.split(nodes: resource_element.xpath('mods:originInfo', mods: DESC_METADATA_NS))

          build_grouped_origin_infos(altrepgroup_origin_info_nodes) + build_ungrouped_origin_infos(other_origin_info_nodes)
        end

        private

        attr_reader :resource_element, :notifier

        def build_grouped_origin_infos(grouped_origin_infos)
          grouped_origin_infos.map do |origin_info_nodes|
            all_grouped_events = origin_info_nodes.map { |origin_info_node| build_ungrouped_origin_infos([origin_info_node]) }
            # Make the eventType=publication for any without types.
            all_grouped_events.each { |event_group| event_group.each { |event| event[:type] = 'publication' unless event[:type] } }

            base_event_group = all_grouped_events.first
            base_event_group_map = {}
            base_event_group.each { |event| base_event_group_map[event[:type]] = event }
            rest_grouped_events = all_grouped_events.drop(1)

            rest_grouped_events.each do |grouped_events|
              grouped_events.each do |grouped_event|
                merge_parallel_grouped_event(grouped_event, base_event_group, base_event_group_map)
              end
            end
            base_event_group
          end.flatten
        end

        def merge_parallel_grouped_event(grouped_event, base_event_group, base_event_group_map)
          if base_event_group_map.include?(grouped_event[:type])
            base_event = base_event_group_map[grouped_event[:type]]
            # Merge them.
            merge_descriptive_value(:date, base_event, grouped_event, ->(value) { value[:structuredValue].nil? })
            merge_descriptive_value(:date, base_event, grouped_event, ->(value) { value[:structuredValue].present? })
            merge_descriptive_value(:location, base_event, grouped_event)
            merge_descriptive_value(:note, base_event, grouped_event, ->(value) { value[:type] == 'edition' })
            merge_descriptive_value(:note, base_event, grouped_event, ->(value) { value[:type] != 'edition' })
            base_name = base_event[:contributor]&.first
            if base_name.nil?
              base_event[:contributor] = grouped_event[:contributor] if grouped_event[:contributor]
            else
              merge_descriptive_value(:name, base_name, grouped_event[:contributor]&.first)
            end
          else
            base_event_group << grouped_event
            base_event_group_map[grouped_event[:type]] = grouped_event
          end
        end

        # rubocop:disable Metrics/AbcSize
        def merge_descriptive_value(key, base_event, grouped_event, filter = ->(_value) { true })
          return if grouped_event.nil?

          filtered_base_values = base_event.fetch(key, []).select { |value| filter.call(value) }
          filtered_grouped_values = grouped_event.fetch(key, []).select { |value| filter.call(value) }

          grouped_event_size = filtered_grouped_values.size
          merge_size = [filtered_base_values.size, grouped_event_size].min
          (0..merge_size - 1).each do |index|
            base_value = filtered_base_values[index]
            grouped_value = filtered_grouped_values[index]

            next if base_value == grouped_value

            unless base_value[:parallelValue]
              # Note that this valueLanguage shuffling is only for contributor/names
              base_parallel_value = base_value.merge({ valueLanguage: base_event[:valueLanguage] }.compact)
              base_value.clear
              if base_parallel_value[:type]
                base_value[:type] = base_parallel_value[:type]
                base_parallel_value.delete(:type)
              end
              base_value[:parallelValue] = [base_parallel_value]
              base_event.delete(:valueLanguage)
            end
            new_grouped_value = grouped_value.merge({ valueLanguage: grouped_event[:valueLanguage] }.compact)
            new_grouped_value.delete(:type)
            base_value[:parallelValue] << new_grouped_value
          end
          # Add any extra values that are in grouped_event
          other_values = filtered_grouped_values.slice(merge_size, grouped_event_size - merge_size)

          return if other_values.blank?

          base_event[key] ||= []
          base_event[key].concat(other_values)
        end
        # rubocop:enable Metrics/AbcSize

        def build_ungrouped_origin_infos(origin_infos)
          origin_infos.flat_map do |origin_info|
            language_script = LanguageScript.build(node: origin_info)
            events = build_events_for_origin_info(origin_info, language_script)

            issuance = origin_info.xpath('mods:issuance', mods: DESC_METADATA_NS)
            frequency = origin_info.xpath('mods:frequency', mods: DESC_METADATA_NS)
            edition = origin_info.xpath('mods:edition', mods: DESC_METADATA_NS)
            publisher = origin_info.xpath('mods:publisher', mods: DESC_METADATA_NS)
            if issuance.present? || frequency.present? || edition.present? || publisher.present?
              event = find_event_by_precedence(events, create: true)
              add_edition_info(event, edition, language_script)
              add_issuance_info(event, issuance)
              add_frequency_info(event, frequency)
              add_publisher_info(event, publisher, language_script)
            end

            events = [{}] if events.empty?
            place = origin_info.xpath('mods:place', mods: DESC_METADATA_NS)
            add_place_info(find_event_by_precedence(events) || events.last, place, language_script) if place.present?

            display_label = origin_info[:displayLabel].presence
            events.first[:displayLabel] = display_label if display_label

            events.reject(&:blank?)
          end
        end

        def find_event_by_precedence(events, create: false)
          %w[publication presentation distribution production creation manufacture].each do |event_type|
            events.each do |event|
              return event if event[:type] == event_type
            end
          end

          # Any event which isn't empty.
          events.each(&:present?)

          return nil unless create

          { type: 'publication' }.tap do |event|
            events << event
          end
        end

        def build_events_for_origin_info(origin_info, language_script)
          [].tap do |events|
            date_created = origin_info.xpath('mods:dateCreated', mods: DESC_METADATA_NS)
            events << build_event('creation', date_created, language_script) if date_created.present?

            date_issued = origin_info.xpath('mods:dateIssued', mods: DESC_METADATA_NS)
            if date_issued.present?
              event_type = origin_info['eventType'] == 'presentation' ? 'presentation' : 'publication'
              events << build_event(event_type, date_issued, language_script)
            end

            copyright_date = origin_info.xpath('mods:copyrightDate', mods: DESC_METADATA_NS)
            events << build_event('copyright', copyright_date, language_script) if copyright_date.present?

            date_captured = origin_info.xpath('mods:dateCaptured', mods: DESC_METADATA_NS)
            events << build_event('capture', date_captured, language_script) if date_captured.present?

            date_other = origin_info.xpath('mods:dateOther', mods: DESC_METADATA_NS)
            events << build_event(date_other_event_type(origin_info, date_other.first), date_other, language_script) if date_other.present?

            has_date = [date_created, date_issued, copyright_date, date_captured, date_other].flatten.present?
            events << build_event('creation', [], language_script) if origin_info[:eventType] == 'production' && !has_date
          end
        end

        def add_place_info(event, places, language_script)
          # Text then code.
          text_places = places.select { |place| place.xpath("mods:placeTerm[not(@type='code')]", mods: DESC_METADATA_NS).present? }
          text_locations = text_places.map do |place|
            text_place_term = place.xpath("mods:placeTerm[not(@type='code')]", mods: DESC_METADATA_NS).first
            code_place_term = place.xpath("mods:placeTerm[@type='code']", mods: DESC_METADATA_NS).first
            location = with_uri_info({}, text_place_term)
            location[:value] = text_place_term.text
            location[:code] = code_place_term.text if code_place_term
            location[:valueLanguage] = language_script if language_script
            location[:type] = 'supplied' if place[:supplied] == 'yes'
            location
          end

          code_places = places.reject { |place| text_places.include?(place) }
          code_locations = code_places.map do |place|
            place_term = place.xpath("mods:placeTerm[@type='code']", mods: DESC_METADATA_NS).first
            location = with_uri_info({}, place_term)
            location[:code] = place_term.text
            location[:type] = 'supplied' if place[:supplied] == 'yes'
            location
          end

          event[:location] = text_locations + code_locations
        end

        def with_uri_info(cocina, xml_node)
          cocina[:uri] = ValueURI.sniff(xml_node['valueURI'], notifier) if xml_node['valueURI']
          source = {
            code: Authority.normalize_code(xml_node['authority'], notifier),
            uri: Authority.normalize_uri(xml_node['authorityURI'])
          }.compact
          cocina[:source] = source if source.present?
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

        def add_edition_info(event, set, language_script)
          return if set.empty?

          event[:note] ||= []
          set.each do |edition|
            event[:note] << {
              type: 'edition',
              value: edition.text,
              valueLanguage: language_script
            }.compact
          end
        end

        def add_publisher_info(event, set, language_script)
          return if set.empty?

          event[:contributor] ||= []
          set.each do |publisher|
            event[:contributor] << {
              name: [
                {
                  value: publisher.text,
                  valueLanguage: language_script || LanguageScript.build(node: publisher)
                }.tap do |attrs|
                  if publisher['transliteration']
                    attrs[:type] = 'transliteration'
                    attrs[:standard] = { value: publisher['transliteration'] }
                  end
                end.compact
              ],
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
            }.compact
          end
        end

        def build_event(type, node_set, language_script = nil)
          dates = node_set.reject { |node| node['point'] }.map do |node|
            addl_attributes = node['encoding'].nil? && language_script ? { valueLanguage: language_script } : {}
            build_date(type, node).merge(addl_attributes)
          end

          points = node_set.select { |node| node['point'] }
          points_date = points.size == 1 ? build_date(type, points.first) : build_structured_date(type, points)
          dates << points_date if points_date

          notifier.warn('originInfo/dateOther missing eventType') unless type

          {
            type: type,
            date: dates.presence
          }.compact
        end

        def build_structured_date(type, node_set)
          return nil if node_set.blank?

          dates = node_set.map { |node| build_date(type, node) }
          { structuredValue: dates }
        end

        def build_date(event_type, node)
          {}.tap do |date|
            date[:value] = clean_date(node.text)
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

        def clean_date(date)
          return date unless date.match(/^\d{4}\.$/)

          date.delete_suffix('.')
        end

        def date_other_event_type(origin, date)
          return 'development' if date['type'] == 'developed'
          return 'creation' if origin['eventType'] == 'production'

          origin['eventType']
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end

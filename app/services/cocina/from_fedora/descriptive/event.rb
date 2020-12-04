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
          events = []
          with_groups = resource_element.xpath('mods:originInfo[@altRepGroup]', mods: DESC_METADATA_NS)
          grouped = with_groups.group_by { |node| node['altRepGroup'] }

          events += build_grouped_origin_infos(grouped)

          without_groups = resource_element.xpath('mods:originInfo[not(@altRepGroup)]', mods: DESC_METADATA_NS)
          events + build_ungrouped_origin_infos(without_groups)
        end

        private

        attr_reader :resource_element

        # @param [Hash[String, Array[Nokogiri::XML::NodeSet]]] grouped_origin_infos hash of key altRepGroup, value Array of NodeSets for originInfo elements in the grouping
        def build_grouped_origin_infos(grouped_origin_infos)
          grouped_origin_infos.map do |_k, node_set_array|
            events = build_ungrouped_origin_infos([node_set_array.first])
            first_attribs = node_set_array.first&.attributes
            first_script = first_attribs['script']&.value
            first_lang_code = first_attribs['lang']&.value
            event_type = first_attribs['eventType']&.value || 'publication'
            el_names_in_common = child_element_names_in_common(node_set_array)
            build_parallel_values(events, node_set_array.drop(1), el_names_in_common, first_script, first_lang_code, event_type)
            events.reject(&:blank?)
          end.flatten
        end

        def child_element_names_in_common(node_set_array)
          candidates = node_set_array.first.element_children.map(&:name).uniq
          node_set_array.each do |node_set|
            # set intersection to the rescue!
            candidates &= node_set.element_children.map(&:name).uniq
          end
          candidates
        end

        # rubocop:disable Metrics/ParameterLists
        def build_parallel_values(events, node_set_array, el_names_in_common, first_script, first_lang_code, event_type)
          node_set_array.each do |origin_info_node_set|
            parallel_attribs = origin_info_node_set&.attributes
            parallel_script = parallel_attribs['script']&.value
            parallel_lang_code = parallel_attribs['lang']&.value
            origin_info_node_set.element_children.each do |child_el|
              child_el_name = child_el.name
              if el_names_in_common.include?(child_el_name)
                build_parallel_value(events, child_el, first_script, parallel_script, first_lang_code, parallel_lang_code, event_type)
              else
                errmsg = "problem building event parallel values due to unmatched originInfo element #{child_el_name}"
                Honeybadger.notify(errmsg)
                logger.error(errmsg)
              end
            end
          end
        end
        # rubocop:enable Metrics/ParameterLists

        # rubocop:disable Metrics/ParameterLists
        def build_parallel_value(events, child_el, orig_script, parallel_script, orig_lang_code, parallel_lang_code, event_type)
          child_el_name = child_el.name
          case child_el_name
          when 'dateIssued'
            add_parallel_publication_date(events, child_el, orig_script, parallel_script)
          when /date/i
            errmsg = "originInfo date flavor #{child_el_name} has unanticipated parallelValue - needs code"
            Honeybadger.notify(errmsg)
            logger.error(errmsg)
          when 'place'
            parallel_place_term = child_el.xpath("mods:placeTerm[not(@type='code')]", mods: DESC_METADATA_NS).first
            parallel_place_value = parallel_place_term&.content
            return if parallel_place_value.blank?

            event = events.find { |e| e[:type] == Cocina::ToFedora::Descriptive::Event::EVENT_TYPE.key(event_type) }
            add_parallel_location(event, parallel_place_value, orig_script, parallel_script, orig_lang_code, parallel_lang_code)
          when 'publisher'
            add_parallel_contributor(events, child_el, orig_script, parallel_script)
          when 'edition'
            puts 'TODO: implement parallelValues for edition'
            # add_parallel_edition_shit(events, child_el, orig_script, parallel_script)
          when 'issuance', 'frequency'
            errmsg = "originInfo #{child_el_name} has unanticipated parallelValue - needs code"
            Honeybadger.notify(errmsg)
            logger.error(errmsg)
          else
            errmsg = "originInfo has unexpected child node #{child_el_name}"
            Honeybadger.notify("[DATA ERROR] #{errmsg}", { tags: 'data_error' })
            logger.error("DATA ERROR: #{errmsg}")
          end
        end
        # rubocop:enable Metrics/ParameterLists

        def build_ungrouped_origin_infos(origin_infos)
          origin_infos.flat_map do |origin_info|
            events = build_events_for_origin_info(origin_info, origin_info[:displayLabel])

            events = [{}] if events.empty?

            place = origin_info.xpath('mods:place', mods: DESC_METADATA_NS)
            add_place_info(events.last, place) if place.present?

            issuance = origin_info.xpath('mods:issuance', mods: DESC_METADATA_NS)
            frequency = origin_info.xpath('mods:frequency', mods: DESC_METADATA_NS)
            edition = origin_info.xpath('mods:edition', mods: DESC_METADATA_NS)
            publisher = origin_info.xpath('mods:publisher', mods: DESC_METADATA_NS)
            if issuance.present? || frequency.present? || edition.present? || publisher.present?
              event = find_or_create_event_by_precedence(events)
              add_issuance_info(event, issuance)
              add_frequency_info(event, frequency)
              add_edition_info(event, edition)
              add_publisher_info(event, publisher)
            end
            events.reject(&:blank?)
          end
        end

        def find_or_create_event_by_precedence(events)
          %w[publication distribution production creation manufacture].each { |event_type| events.each { |event| return event if event[:type] == event_type } }

          { type: 'publication' }.tap do |event|
            events << event
          end
        end

        def build_events_for_origin_info(origin_info, display_label)
          [].tap do |events|
            date_created = origin_info.xpath('mods:dateCreated', mods: DESC_METADATA_NS)
            events << build_event('creation', date_created, display_label) if date_created.present?

            date_issued = origin_info.xpath('mods:dateIssued', mods: DESC_METADATA_NS)
            events << build_event('publication', date_issued, display_label) if date_issued.present?

            copyright_date = origin_info.xpath('mods:copyrightDate', mods: DESC_METADATA_NS)
            events << build_event('copyright', copyright_date, display_label) if copyright_date.present?

            date_captured = origin_info.xpath('mods:dateCaptured', mods: DESC_METADATA_NS)
            events << build_event('capture', date_captured, display_label) if date_captured.present?

            date_other = origin_info.xpath('mods:dateOther', mods: DESC_METADATA_NS)
            events << build_event(date_other_event_type(origin_info), date_other, display_label) if date_other.present?

            has_date = [date_created, date_issued, copyright_date, date_captured, date_other].flatten.present?
            events << build_event('creation', [], display_label) if origin_info[:eventType] == 'production' && !has_date
          end
        end

        def add_place_info(event, place_set)
          event[:location] = place_set.map do |place|
            text_place_term = place.xpath("mods:placeTerm[not(@type='code')]", mods: DESC_METADATA_NS).first
            code_place_term = place.xpath("mods:placeTerm[@type='code']", mods: DESC_METADATA_NS).first

            return nil unless text_place_term || code_place_term

            location = with_uri_info({}, text_place_term || code_place_term)

            location[:code] = code_place_term.text if code_place_term
            location[:value] = text_place_term.text if text_place_term
            location
          end.compact
        end

        # rubocop:disable Metrics/ParameterLists
        def add_parallel_location(event, parallel_place_value, orig_script, parallel_script, orig_lang_code, parallel_lang_code)
          orig_locations = event[:location]
          orig_location_value = first_value(orig_locations)
          return nil unless orig_location_value

          parallel_value = parallel_value(orig_location_value, parallel_place_value, orig_script, parallel_script)
          if orig_locations.size > 1
            additional_values = orig_locations.select { |location| location[:value].present? && location[:value] != orig_location_value }
            parallel_value = add_to_parallel_value(parallel_value, additional_values) if additional_values.present?
          end
          orig_w_value = first_with_value(orig_locations)
          add_parallel_location_lang_info(parallel_value, orig_w_value, orig_lang_code, parallel_lang_code)
          event[:location] = [parallel_value]

          addl_locations = orig_locations.reject { |location| location[:value].present? }
          addl_locations.each { |location_val| event[:location] << location_val }
        end
        # rubocop:enable Metrics/ParameterLists

        def add_parallel_location_lang_info(parallel_value, orig_w_value, orig_lang_code, parallel_lang_code)
          parallel_value[:parallelValue].first[:uri] = orig_w_value[:uri] if orig_w_value[:uri]
          parallel_value[:parallelValue].first[:source] = orig_w_value[:source] if orig_w_value[:source]
          if orig_lang_code
            parallel_value[:parallelValue].first[:valueLanguage][:code] = orig_lang_code
            parallel_value[:parallelValue].first[:valueLanguage][:source] = { code: 'iso639-2b' }
          end

          return if parallel_lang_code.blank?

          parallel_value[:parallelValue].second[:valueLanguage][:code] = parallel_lang_code
          parallel_value[:parallelValue].second[:valueLanguage][:source] = { code: 'iso639-2b' }
        end

        def first_with_value(desc_value_array)
          desc_value_array&.find { |desc_value| desc_value[:value].present? }
        end

        def first_value(desc_value_array)
          first_with_value(desc_value_array)[:value]
        end

        def with_uri_info(cocina, xml_node)
          cocina[:uri] = xml_node['valueURI'] if xml_node['valueURI']
          if xml_node['authority']
            cocina[:source] = {
              code: Authority.normalize_code(xml_node['authority']),
              uri: Authority.normalize_uri(xml_node['authorityURI'])
            }.compact
          elsif xml_node['authorityURI'] # used for originInfo placeTermn
            cocina[:source] = {
              # code: xml_node['authorityURI'],
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

        def add_parallel_contributor(events, parallel_xml_node, orig_script, parallel_script)
          parallel_contrib_value = parallel_xml_node&.content
          return nil unless parallel_contrib_value

          publication_event = events.find { |event| event[:type] == 'publication' }

          orig_contributors = publication_event[:contributor]
          orig_contrib_name_value = first_contrib_name_value(orig_contributors)
          return nil unless orig_contrib_name_value

          parallel_value = parallel_value(orig_contrib_name_value, parallel_contrib_value, orig_script, parallel_script)
          if orig_contributors.size > 1
            additional_values = orig_contributors.select do |contrib|
              contrib[:name].first[:value].present? && contrib[:name].first[:value] != orig_contrib_name_value
            end
            parallel_value = add_to_parallel_value(parallel_value, additional_values) if additional_values.present?
          end
          publication_event[:contributor].first[:name] = [parallel_value]

          addl_contributors = orig_contributors.reject { |contrib| contrib[:name].present? }
          addl_contributors.each { |contrib_val| publication_event[:contributor] << contrib_val }
        end

        def first_contrib_name_value(orig_contributors)
          orig_contrib_name_w_value = orig_contributors&.find do |contrib|
            first_contrib_name = contrib[:name]&.first
            first_contrib_name[:value].present?
          end
          orig_contrib_name_w_value[:name].first[:value] if orig_contrib_name_w_value
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

        def add_parallel_publication_date(events, parallel_xml_node, orig_script, parallel_script)
          parallel_date_value = parallel_xml_node&.content
          return nil unless parallel_date_value

          publication_event = events.find { |event| event[:type] == 'publication' }

          orig_pub_dates = publication_event[:date]
          orig_pub_date_value = first_value(orig_pub_dates)
          return nil unless orig_pub_date_value

          parallel_value = parallel_value(orig_pub_date_value, parallel_date_value, orig_script, parallel_script)
          additional_values = orig_pub_dates.reject { |date| date[:value] == orig_pub_date_value } if orig_pub_dates.size > 1
          parallel_value = add_to_parallel_value(parallel_value, additional_values) if additional_values.present?
          publication_event[:date] = [parallel_value]

          other_pub_dates = orig_pub_dates.reject { |date| date[:value].present? }
          other_pub_dates.each { |pub_date| publication_event[:date] << pub_date }
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

        def parallel_value(first_value, second_value, first_script, second_script)
          {
            parallelValue: [
              {
                value: first_value,
                valueLanguage: {
                  valueScript: {
                    code: first_script,
                    source: { code: 'iso15924' }
                  }
                }
              },
              {
                value: second_value,
                valueLanguage: {
                  valueScript: {
                    code: second_script,
                    source: { code: 'iso15924' }
                  }
                }
              }
            ]
          }
        end

        def add_to_parallel_value(parallel_value_struct, additional_values)
          {
            parallelValue: parallel_value_struct[:parallelValue] + additional_values
          }
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end

# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps originInfo to cocina events
      # rubocop:disable Metrics/ClassLength
      class Event
        # key: MODS date element name
        # value: cocina date type
        DATE_ELEMENTS_2_TYPE = {
          'copyrightDate' => 'copyright',
          'dateCaptured' => 'capture',
          'dateCreated' => 'creation',
          'dateIssued' => 'publication',
          'dateModified' => 'modification',
          'dateOther' => '', # cocina type is set differently for dateOther
          'dateValid' => 'validity'
        }.freeze

        # a preferred vocabulary, if you will
        EVENT_TYPES = [
          'acquisition',
          'capture',
          'collection',
          'copyright',
          'creation',
          'degree conferral',
          'development',
          'distribution',
          'generation',
          'manufacture',
          'modification',
          'performance',
          'presentation',
          'production',
          'publication',
          'recording',
          'release',
          'submission',
          'validity',
          'withdrawal'
        ].freeze

        # because eventType is a relatively new addition to the MODS schema, records converted from MARC to MODS prior
        #   to its introduction used displayLabel as a stopgap measure.
        # These are the displayLabel values that should be converted to eventType instead of displayLabel.
        # These values were also sometimes used as eventType values themselves, and will be converted to our preferred vocab.
        LEGACY_EVENT_TYPES_2_TYPE = {
          'distributor' => 'distribution',
          'manufacturer' => 'manufacture',
          'producer' => 'production',
          'publisher' => 'publication'
        }.freeze

        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @param [String] purl
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder:, purl: nil)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @notifier = descriptive_builder.notifier
        end

        def build
          altrepgroup_origin_info_nodes, other_origin_info_nodes = AltRepGroup.split(nodes: resource_element.xpath('mods:originInfo', mods: DESC_METADATA_NS))

          results = build_grouped_origin_infos(altrepgroup_origin_info_nodes) + build_ungrouped_origin_infos(other_origin_info_nodes)
          results if results.present? && results.first.present? # avoid [{}] case
        end

        private

        attr_reader :resource_element, :notifier

        def build_ungrouped_origin_infos(origin_infos)
          origin_infos.map do |origin_info|
            next if origin_info.content.blank? &&
                    origin_info.xpath('//*[@valueURI]').empty? &&
                    origin_info.xpath('//*[@xlink:href]', xlink: XLINK_NS).empty?

            event = build_event_for_origin_info(origin_info)
            event.compact
          end.compact
        end

        def build_event_for_origin_info(origin_info_node)
          return build_copyright_notice_event(origin_info_node) if origin_info_node['eventType'] == 'copyright notice'

          event = {
            type: event_type(origin_info_node),
            displayLabel: display_label(origin_info_node),
            valueLanguage: LanguageScript.build(node: origin_info_node)
          }
          add_info_to_event(event, origin_info_node)
          event.compact
        end

        def build_grouped_origin_infos(grouped_origin_infos)
          grouped_origin_infos.map do |origin_info_nodes|
            common_event_type = event_type_in_common(origin_info_nodes)
            common_display_label = display_label_in_common(origin_info_nodes)

            parallel_event = {
              type: common_event_type,
              displayLabel: common_display_label,
              parallelEvent: build_parallel_origin_infos(origin_info_nodes, common_event_type, common_display_label)
            }

            parallel_event.compact
          end.flatten
        end

        # For parallelEvent items, the valueLanguage construct is at the same level as the rest
        #   of the event attributes, rather than inside each event attribute
        def build_parallel_origin_infos(origin_infos, common_event_type, common_display_label)
          origin_infos.flat_map do |origin_info|
            event = build_event_for_parallel_origin_info(origin_info)
            event[:valueLanguage] = LanguageScript.build(node: origin_info)
            event[:type] = display_label(origin_info) if common_event_type.blank?
            event[:displayLabel] = display_label(origin_info) if common_display_label.blank?

            event.compact
          end.compact
        end

        def build_event_for_parallel_origin_info(origin_info_node)
          return build_copyright_notice_event(origin_info_node) if origin_info_node['eventType'] == 'copyright notice'

          event = {}
          add_info_to_event(event, origin_info_node)
          event.compact
        end

        # @return String type for the cocina event if it is the same for all the origin_info_nodes, o.w. nil
        def event_type_in_common(origin_info_nodes)
          raw_type = origin_info_nodes.first['eventType']
          return if raw_type.blank?

          first_event_type = event_type(origin_info_nodes.first)
          return first_event_type if origin_info_nodes.all? { |node| event_type(node) == first_event_type }
        end

        # @return String displayLabel for the cocina event if it is the same for all the origin_info_nodes, o.w. nil
        def display_label_in_common(origin_info_nodes)
          raw_label = origin_info_nodes.first['displayLabel']
          return if raw_label.blank?

          first_label = display_label(origin_info_nodes.first)
          return first_label if origin_info_nodes.all? { |node| display_label(node) == first_label }
        end

        def add_info_to_event(event, origin_info_node)
          place_nodes = origin_info_node.xpath('mods:place', mods: DESC_METADATA_NS)
          add_place_info(event, place_nodes) if place_nodes.present?

          publisher = origin_info_node.xpath('mods:publisher', mods: DESC_METADATA_NS)
          add_publisher_info(event, publisher, origin_info_node) if publisher.present?

          issuance = origin_info_node.xpath('mods:issuance', mods: DESC_METADATA_NS)
          add_issuance_note(event, issuance) if issuance.present?

          edition = origin_info_node.xpath('mods:edition', mods: DESC_METADATA_NS)
          add_edition_info(event, edition) if edition.present?

          frequency = origin_info_node.xpath('mods:frequency', mods: DESC_METADATA_NS)
          add_frequency_info(event, frequency) if frequency.present?

          date_values = build_date_values(origin_info_node)
          event[:date] = date_values if date_values.present?
        end

        XPATH_HAS_CONTENT_PREDICATE = '[string-length(normalize-space()) > 0]'

        def build_copyright_notice_event(origin_info_node)
          date_nodes = origin_info_node.xpath("mods:copyrightDate#{XPATH_HAS_CONTENT_PREDICATE}", mods: DESC_METADATA_NS)
          return if date_nodes.blank?

          {
            type: 'copyright notice',
            note: [
              {
                value: date_nodes.first.content,
                type: 'copyright statement'
              }
            ]
          }
        end

        def build_date_values(origin_info_node)
          date_values = []
          DATE_ELEMENTS_2_TYPE.each do |mods_el_name, cocina_type|
            date_values << build_date_desc_values(mods_el_name, origin_info_node, cocina_type)
          end
          date_values.flatten.compact
        end

        def build_date_desc_values(mods_date_el_name, origin_info_node, default_type)
          date_nodes = origin_info_node.xpath("mods:#{mods_date_el_name}#{XPATH_HAS_CONTENT_PREDICATE}", mods: DESC_METADATA_NS)
          if mods_date_el_name == 'dateOther' && date_nodes.present?
            date_other_type = date_other_type_attr(origin_info_node['eventType'], date_nodes.first)
            date_values_for_event(date_nodes, date_other_type)
          else
            date_values_for_event(date_nodes, default_type)
          end
        end

        # encapsulate where warnings are given for dateOther@type
        # per Arcadia: no date type/no event type warns 'undetermined date type'
        def date_other_type_attr(event_type, date_other_node)
          date_type = date_other_node['type']
          notifier.warn('Undetermined date type') if date_type.blank? && event_type.blank?
          date_type
        end

        def date_values_for_event(date_nodes, default_type)
          dates = date_nodes.reject { |node| node['point'] }.map do |node|
            addl_attributes = {}
            # NOTE: only dateOther should have type attribute;  not sure if we have dirty data in this respect.
            #   If so, it's invalid MODS, so validating against the MODS schema will catch it
            addl_attributes[:type] = node['type'] if node['type'].present?
            build_date(node).merge(addl_attributes)
          end

          points = date_nodes.select { |node| node['point'] }
          points_date = build_structured_date(points)
          dates << points_date if points_date

          dates.compact!
          dates.each { |date| date[:type] = default_type if date[:type].blank? && default_type.present? }
        end

        # map legacy event types, encapsulate where warnings are given for originInfo@eventType
        #  per Arcadia:  unknown event type/any date type warns 'unrecognized event type'
        # NOTE: Do any eventType/displayLabel transformations before determining contributor role
        def event_type(origin_info_node)
          event_type = origin_info_node['eventType']
          event_type = origin_info_node['displayLabel'] if event_type.blank? &&
                                                           LEGACY_EVENT_TYPES_2_TYPE.key?(origin_info_node['displayLabel'])
          event_type = LEGACY_EVENT_TYPES_2_TYPE[event_type] if LEGACY_EVENT_TYPES_2_TYPE.key?(event_type)

          return if event_type.blank?

          notifier.warn('Unrecognized event type') unless EVENT_TYPES.include?(event_type)
          event_type
        end

        def display_label(origin_info_node)
          origin_info_node[:displayLabel] if origin_info_node[:displayLabel].present? &&
                                             !LEGACY_EVENT_TYPES_2_TYPE.key?(origin_info_node[:displayLabel])
        end

        # placeTerm can have type=code or type=text or neither; placeTerms of type code and text may combine into a single
        #  cocina location (when under the same place element), or they might refer to separate cocina locations (under separate place elements)
        def add_place_info(event, place_nodes)
          return unless place_nodes_have_info?(place_nodes)

          # text only and text-and-code placeTerm types in single place node
          text_places = place_nodes.select { |place| place.xpath("mods:placeTerm[not(@type='code')]", mods: DESC_METADATA_NS).present? }
          code_only_places = place_nodes.reject { |place| text_places.include?(place) }

          event[:location] = locations_for_place_terms_with_text(text_places) + locations_for_code_only_place_terms(code_only_places)
          event[:location].compact!
        end

        def place_nodes_have_info?(place_nodes)
          return true if place_nodes.any? { |node| node.content.present? }
          return true if place_nodes.any? { |node| node.xpath('mods:placeTerm[@valueURI]', mods: DESC_METADATA_NS).present? }

          place_nodes.any? { |node| node.xpath('mods:placeTerm[@xlink:href]', { mods: DESC_METADATA_NS, xlink: XLINK_NS }).present? }
        end

        # @param [Nokogiri::XML::NodeSet] place elements that have at least one placeTerm child of type text
        # @return cocina locations
        def locations_for_place_terms_with_text(place_nodes)
          place_nodes.map do |place_node|
            text_place_term_node = place_node.xpath("mods:placeTerm[not(@type='code')]", mods: DESC_METADATA_NS).first
            next if text_place_term_node.text.blank?

            cocina_location = {}
            add_authority_info(cocina_location, text_place_term_node)
            cocina_location[:value] = text_place_term_node.text
            code_place_term_node = place_node.xpath("mods:placeTerm[@type='code']", mods: DESC_METADATA_NS).first
            if code_place_term_node
              cocina_location[:code] = code_place_term_node.text
              # NOTE: deliberately skipping situation where text node has some authority info and code node
              #  has other authority info as we may never encounter this
              add_authority_info(cocina_location, code_place_term_node) if cocina_location[:source].blank? && cocina_location[:uri].blank?
            end
            lang_script = LanguageScript.build(node: text_place_term_node)
            cocina_location[:valueLanguage] = lang_script if lang_script
            cocina_location[:type] = 'supplied' if place_node[:supplied] == 'yes'
            cocina_location.compact
          end
        end

        # @param [Nokogiri::XML::NodeSet] place elements that have placeTerm children ONLY of type code
        # @return cocina locations
        def locations_for_code_only_place_terms(place_nodes)
          place_nodes.map do |place_node|
            code_place_term_node = place_node.xpath("mods:placeTerm[@type='code']", mods: DESC_METADATA_NS).first
            next if code_place_term_node.content.blank?

            cocina_location = {}
            add_authority_info(cocina_location, code_place_term_node)
            notifier.warn('Place code missing authority', { code: code_place_term_node.text }) if cocina_location.empty?

            cocina_location[:code] = code_place_term_node.text
            cocina_location[:type] = 'supplied' if place_node[:supplied] == 'yes'
            cocina_location.compact
          end
        end

        def add_issuance_note(event, issuance_nodes)
          return if issuance_nodes.empty?

          event[:note] ||= []
          issuance_nodes.each do |issuance|
            next if issuance.text.blank?

            event[:note] << {
              source: { value: 'MODS issuance terms' },
              type: 'issuance',
              value: issuance.text
            }.compact
          end
        end

        def add_frequency_info(event, freq_nodes)
          return if freq_nodes.empty?

          event[:note] ||= []
          freq_nodes.each do |frequency|
            next if frequency.text.blank?

            note = {
              type: 'frequency',
              value: frequency.text,
              valueLanguage: LanguageScript.build(node: frequency)
            }
            add_authority_info(note, frequency).compact
            event[:note] << note.compact
          end
        end

        def add_edition_info(event, edition_nodes)
          return if edition_nodes.empty?

          event[:note] ||= []
          edition_nodes.each do |edition|
            next if edition.text.blank?

            event[:note] << {
              type: 'edition',
              value: edition.text,
              valueLanguage: LanguageScript.build(node: edition)
            }.compact
          end
        end

        def add_publisher_info(event, publisher_nodes, origin_info_node)
          return if publisher_nodes.empty?

          event[:contributor] ||= []
          publisher_nodes.each do |publisher_node|
            next if publisher_node.text.blank?

            event[:contributor] << {
              name: [
                {
                  value: publisher_node.text,
                  valueLanguage: LanguageScript.build(node: publisher_node)
                }.tap do |attrs|
                  if origin_info_node['transliteration']
                    attrs[:type] = 'transliteration'
                    attrs[:standard] = { value: origin_info_node['transliteration'] }
                  end
                  if publisher_node['transliteration']
                    attrs[:type] = 'transliteration'
                    attrs[:standard] = { value: publisher_node['transliteration'] }
                  end
                end.compact
              ],
              role: [role_for(event)]
            }.compact
          end

          event.delete(:contributor) if event[:contributor].empty?
        end

        def add_authority_info(cocina_desc_val, xml_node)
          cocina_desc_val[:uri] = ValueURI.sniff(xml_node['valueURI'], notifier) if xml_node['valueURI']
          source = {
            code: Authority.normalize_code(xml_node['authority'], notifier),
            uri: Authority.normalize_uri(xml_node['authorityURI'])
          }.compact
          cocina_desc_val[:source] = source if source.present?
          cocina_desc_val
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def build_structured_date(date_nodes)
          return if date_nodes.blank?

          common_attribs = common_date_attributes(date_nodes)

          remove_dup_key_date_from_end_point(date_nodes)
          dates = date_nodes.map do |node|
            next if node.text.blank? && node.attributes.empty?

            new_node = node.deep_dup
            new_node.remove_attribute('encoding') if common_attribs[:encoding].present? || node[:encoding]&.size&.zero?
            new_node.remove_attribute('qualifier') if common_attribs[:qualifier].present? || node[:qualifier]&.size&.zero?
            build_date(new_node)
          end
          { structuredValue: dates }.merge(common_attribs).compact
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        # Per Arcadia, keyDate should only appear once in an originInfo.
        # If keyDate is on a date of type point and is on both the start and end points, then
        # it should be removed from the end point
        def remove_dup_key_date_from_end_point(date_nodes)
          key_date_point_nodes = date_nodes.select { |node| node['keyDate'] == 'yes' && node['point'].present? }
          return unless key_date_point_nodes.size == 2

          end_node = key_date_point_nodes.find { |node| node['point'] == 'end' }
          end_node.delete('keyDate')
        end

        def common_date_attributes(date_nodes)
          first_encoding = date_nodes.first['encoding']
          first_qualifier = date_nodes.first['qualifier']
          encoding_is_common = date_nodes.all? { |node| node['encoding'] == first_encoding }
          qualifier_is_common = date_nodes.all? { |node| node['qualifier'] == first_qualifier }
          attribs = {}
          attribs[:qualifier] = first_qualifier if qualifier_is_common && first_qualifier.present?
          attribs[:encoding] = { code: first_encoding } if encoding_is_common && first_encoding.present?
          attribs.compact
        end

        def build_date(date_node)
          {}.tap do |date|
            date[:value] = clean_date(date_node.text) if date_node.text.present?
            date[:encoding] = { code: date_node['encoding'] } if date_node['encoding']
            date[:status] = 'primary' if date_node['keyDate']
            date[:note] = build_date_note(date_node)
            date[:qualifier] = date_node['qualifier'] if date_node['qualifier'].present?
            date[:type] = date_node['point'] if date_node['point'].present?
            date[:valueLanguage] = LanguageScript.build(node: date_node)
          end.compact
        end

        def build_date_note(date_node)
          return if date_node['calendar'].blank?

          [
            {
              value: date_node['calendar'],
              type: 'calendar'
            }
          ]
        end

        def clean_date(date)
          date.delete_suffix('.')
        end

        # NOTE: Do any eventType/displayLabel transformations before determining role (i.e. with LEGACY_EVENT_TYPES_2_TYPE)
        def role_for(event)
          case event[:type]
          when 'distribution'
            {
              value: 'distributor',
              code: 'dst',
              uri: 'http://id.loc.gov/vocabulary/relators/dst',
              source: {
                code: 'marcrelator',
                uri: 'http://id.loc.gov/vocabulary/relators/'
              }
            }
          when 'manufacture'
            {
              value: 'manufacturer',
              code: 'mfr',
              uri: 'http://id.loc.gov/vocabulary/relators/mfr',
              source: {
                code: 'marcrelator',
                uri: 'http://id.loc.gov/vocabulary/relators/'
              }
            }
          when 'production'
            {
              value: 'creator',
              code: 'cre',
              uri: 'http://id.loc.gov/vocabulary/relators/cre',
              source: {
                code: 'marcrelator',
                uri: 'http://id.loc.gov/vocabulary/relators/'
              }
            }
          else
            {
              value: 'publisher',
              code: 'pbl',
              uri: 'http://id.loc.gov/vocabulary/relators/pbl',
              source: {
                code: 'marcrelator',
                uri: 'http://id.loc.gov/vocabulary/relators/'
              }
            }
          end
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end

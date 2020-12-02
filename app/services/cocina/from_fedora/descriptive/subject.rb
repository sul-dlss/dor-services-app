# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Cocina
  module FromFedora
    class Descriptive
      # Maps subject nodes from MODS to cocina
      class Subject
        NODE_TYPE = {
          'classification' => 'classification',
          'genre' => 'genre',
          'geographic' => 'place',
          'occupation' => 'occupation',
          'temporal' => 'time',
          'topic' => 'topic'
        }.freeze

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
          subjects.map do |subject|
            check_valid_authority(subject)
            attrs = common_attrs(subject)
            node_set = subject.xpath('*')
            next subject_classification(subject, attrs) if subject.name == 'classification'

            is_geo_code = node_set.any? { |node| node.name == 'geographicCode' }

            next geo_code_and_terms(node_set, attrs) if node_set.size != 1 && is_geo_code

            next structured_value(node_set, attrs) if node_set.size != 1 && !is_geo_code

            node = node_set.first
            next hierarchical_geographic(node, attrs) if node.name == 'hierarchicalGeographic'

            simple_item(node, attrs)
          end.compact
        end

        private

        attr_reader :resource_element

        def check_valid_authority(subject)
          return unless subject['authority'] == '#N/A'

          # This is not a fatal problem. Just warn.
          Honeybadger.notify('[DATA ERROR] Subject has authority attribute "#N/A"',
                             tags: 'data_error')
        end

        def common_attrs(subject)
          {
            displayLabel: subject[:displayLabel]
          }.tap do |attrs|
            source = { code: code_for(subject), uri: AuthorityUri.normalize(subject[:authorityURI]), version: edition_for(subject) }.compact
            if subject[:valueURI]
              attrs[:source] = source unless source.empty?
              attrs[:uri] = subject[:valueURI]
            elsif subject[:authority]
              attrs[:source] = source unless source.empty?
            end
            attrs[:encoding] = { code: subject[:encoding] } if subject[:encoding]
          end.compact
        end

        def code_for(subject)
          code = subject[:authority]
          return nil if code.nil?

          unless SubjectAuthorityCodes::SUBJECT_AUTHORITY_CODES.include?(code)
            Honeybadger.notify('[DATA ERROR] Subject has unknown authority code', tags: 'data_error')
            return nil
          end

          code
        end

        def structured_value(node_set, attrs)
          values = node_set.map { |node| simple_item(node) }.compact
          if values.present?
            attrs = attrs.merge(structuredValue: values)
            # Remove source if no source uri and all values have source and all are same type
            attrs.delete(:source) if remove_source?(attrs)
          end
          # Authority should be 'naf', not 'lcsh'
          attrs[:source][:code] = 'naf' if attrs.dig(:source, :uri) == 'http://id.loc.gov/authorities/names/'
          attrs.presence
        end

        def geo_code_and_terms(node_set, attrs)
          values = node_set.map { |node| simple_item(node) }.compact
          if values.present?
            # Removes type from values
            values.each { |value| value.delete(:type) }
            attrs = attrs.merge(parallelValue: values)
          end
          attrs[:type] = 'place'
          attrs.presence
        end

        def remove_source?(attrs)
          # Remove source if no source uri and all values have source and all are not same type
          return false if attrs.dig(:source, :uri)
          return false if attrs[:structuredValue].any? { |value| value[:source].nil? }

          types = attrs[:structuredValue].pluck(:type)
          return false unless types.any? { |type| type != types.first }

          true
        end

        def hierarchical_geographic(hierarchical_geographic_node, attrs)
          node_set = hierarchical_geographic_node.xpath('*')
          values = node_set.map do |node|
            {
              "value": node.text,
              "type": node.name
            }
          end
          attrs.merge(structuredValue: values, type: 'place')
        end

        def subject_classification(subject_classification_node, attrs)
          values = {}.tap do |content|
            content[:type] = 'classification'
            content[:value] = subject_classification_node.text
            content[:displayLabel] = subject_classification_node[:displayLabel] if subject_classification_node[:displayLabel]
          end
          attrs.merge(values)
        end

        def simple_item(node, attrs = {})
          attrs = attrs.merge(common_attrs(node))
          case node.name
          when 'name'
            attrs[:type] = name_type_for_subject(node[:type])
            Contributor.name_parts(node, add_default_type: true)&.first&.merge(attrs)
          when 'titleInfo'
            query = node.xpath('mods:title', mods: DESC_METADATA_NS)
            attrs.merge(value: query.first.text, type: 'title')
          when 'geographicCode'
            attrs.merge(code: node.text, type: 'place', source: { code: node['authority'] })
          when 'cartographics'
            coords = node.xpath('mods:coordinates', mods: DESC_METADATA_NS).first
            return nil if coords.nil?

            attrs.merge(value: coords.text, type: 'map coordinates', encoding: { value: 'DMS' })
          when 'Topic'
            Honeybadger.notify('[DATA ERROR] <subject> has <Topic>; normalized to "topic"', tags: 'data_error')
            attrs.merge(value: node.text, type: 'topic')
          else
            node_type = node_type_for(node)
            attrs.merge(value: node.text, type: node_type) if node_type
          end
        end

        def node_type_for(node)
          return NODE_TYPE.fetch(node.name) if NODE_TYPE.keys.include?(node.name)

          Honeybadger.notify("[DATA ERROR] Unexpected node type for subject: '#{node.name}'",
                             tags: 'data_error')
          nil
        end

        def name_type_for_subject(name_type)
          unless name_type
            Honeybadger.notify('[DATA ERROR] Subject contains a <name> element without a type attribute',
                               tags: 'data_error')
            return 'name'
          end
          unless Contributor::ROLES.keys.include?(name_type)
            Honeybadger.notify("[DATA ERROR] Subject has <name> with an invalid type attribute '#{name_type}'",
                               tags: 'data_error')
            return 'topic' if name_type.downcase == 'topic'

            return 'name'
          end

          Contributor::ROLES.fetch(name_type) if Contributor::ROLES.keys.include?(name_type)
        end

        def subjects
          resource_element.xpath('mods:subject', mods: DESC_METADATA_NS) + resource_element.xpath('mods:classification', mods: DESC_METADATA_NS)
        end

        def edition_for(subject)
          return nil if subject[:edition].nil?

          "#{subject[:edition].to_i.ordinalize} edition"
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength

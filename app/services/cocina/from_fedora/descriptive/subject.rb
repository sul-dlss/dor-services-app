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
        def self.build(resource_element:, descriptive_builder:)
          new(resource_element: resource_element, descriptive_builder: descriptive_builder).build
        end

        def initialize(resource_element:, descriptive_builder:)
          @resource_element = resource_element
          @notifier = descriptive_builder.notifier
        end

        def build
          altrepgroup_subject_nodes, other_subject_nodes = AltRepGroup.split(nodes: subject_nodes)

          altrepgroup_subject_nodes.map { |subject_nodes| build_parallel_subject(subject_nodes) } \
            + other_subject_nodes.map { |subject_node| build_subject(subject_node) }.compact \
            + build_cartographics
        end

        private

        attr_reader :resource_element, :notifier

        def build_parallel_subject(parallel_subject_nodes)
          parallel_subjects = parallel_subject_nodes.map { |subject_node| build_subject(subject_node) }
          # Moving type up from parallel subjects if they are all the same.
          move_type = parallel_subjects.uniq { |subject| subject[:type] }.size == 1
          type = move_type ? parallel_subjects.map { |subject| subject.delete(:type) }.compact.first : nil
          {
            parallelValue: parallel_subjects,
            type: type
          }.compact
        end

        def build_subject(subject_node)
          attrs = common_attrs(subject_node)
          children_nodes = subject_node.xpath('*')
          return subject_classification(subject_node, attrs) if subject_node.name == 'classification'

          return temporal_range(children_nodes, attrs) if children_nodes.all? { |node| node.name == 'temporal' && node['point'] }

          is_geo_code = children_nodes.any? { |node| node.name == 'geographicCode' }
          return geo_code_and_terms(children_nodes, attrs) if children_nodes.size != 1 && is_geo_code

          return structured_value(children_nodes, attrs) if children_nodes.size != 1 && !is_geo_code

          first_child_node = children_nodes.first
          return hierarchical_geographic(first_child_node, attrs) if first_child_node.name == 'hierarchicalGeographic'

          simple_item(first_child_node, attrs)
        end

        def common_attrs(subject)
          {
            displayLabel: subject[:displayLabel]
          }.tap do |attrs|
            source = {
              code: code_for(subject),
              uri: Authority.normalize_uri(subject[:authorityURI]),
              version: edition_for(subject)
            }.compact
            attrs[:source] = source unless source.empty?
            attrs[:uri] = ValueURI.sniff(subject[:valueURI], notifier)
            attrs[:encoding] = { code: subject[:encoding] } if subject[:encoding]
            language_script = LanguageScript.build(node: subject)
            attrs[:valueLanguage] = language_script if language_script
          end.compact
        end

        def code_for(subject)
          code = Authority.normalize_code(subject[:authority], notifier)

          return nil if code.nil?

          unless SubjectAuthorityCodes::SUBJECT_AUTHORITY_CODES.include?(code)
            notifier.warn('Subject has unknown authority code', { code: code })
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
          attrs = attrs.deep_merge(common_attrs(node))
          case node.name
          when 'name'
            name_type = name_type_for_subject(node[:type])
            attrs[:type] = name_type if name_type
            name_attrs = NameBuilder.build(name_elements: [node], add_default_type: true, notifier: notifier)[:name]&.first
            name_attrs&.merge(attrs)
          when 'titleInfo'
            attrs.merge(TitleBuilder.build(title_info_element: node, notifier: notifier)).merge(type: 'title')
          when 'geographicCode'
            attrs.merge(code: node.text, type: 'place', source: { code: node['authority'] })
          when 'cartographics'
            # Cartographics are built separately
            nil
          when 'Topic'
            notifier.warn('<subject> has <Topic>; normalized to "topic"')
            attrs.merge(value: node.text, type: 'topic')
          else
            node_type = node_type_for(node)
            attrs.merge(value: node.text, type: node_type) if node_type
          end
        end

        def node_type_for(node)
          return NODE_TYPE.fetch(node.name) if NODE_TYPE.keys.include?(node.name)

          notifier.warn('Unexpected node type for subject', name: node.name)
          nil
        end

        def name_type_for_subject(name_type)
          unless name_type
            notifier.warn('Subject contains a <name> element without a type attribute')
            return 'name'
          end

          return 'topic' if name_type.downcase == 'topic'

          Contributor::ROLES.fetch(name_type) if Contributor::ROLES.keys.include?(name_type)
        end

        def subject_nodes
          resource_element.xpath('mods:subject', mods: DESC_METADATA_NS) + resource_element.xpath('mods:classification', mods: DESC_METADATA_NS)
        end

        def edition_for(subject)
          return nil if subject[:edition].nil?

          "#{subject[:edition].to_i.ordinalize} edition"
        end

        def temporal_range(children_nodes, attrs)
          attrs[:structuredValue] = children_nodes.map do |node|
            {
              type: node['point'],
              value: node.content
            }
          end
          attrs[:type] = 'time'
          attrs[:encoding] = { code: children_nodes.first['encoding'] }
          attrs
        end

        def build_cartographics
          coordinates = subject_nodes.map do |subject_node|
            coordinate = subject_node.xpath('mods:cartographics/mods:coordinates', mods: DESC_METADATA_NS).first&.content

            next coordinate.delete_prefix('(').delete_suffix(')') if coordinate.present?

            nil
          end.compact.uniq
          coordinates.map { |coordinate| { value: coordinate, type: 'map coordinates' } }
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength

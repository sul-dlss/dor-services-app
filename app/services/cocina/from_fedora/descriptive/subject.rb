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
          altrepgroup_subject_nodes, other_subject_nodes = AltRepGroup.split(nodes: subject_nodes)

          subjects = (altrepgroup_subject_nodes.map { |subject_nodes| build_parallel_subject(subject_nodes) } +
            other_subject_nodes.map { |subject_node| build_subject(subject_node) }.compact +
            build_cartographics).compact
          Primary.adjust(subjects, 'classification', notifier, match_type: true)
          Primary.adjust(subjects.reject { |subject| subject[:type] == 'classification' }, 'subject', notifier)
          subjects
        end

        private

        attr_reader :resource_element, :notifier

        def build_parallel_subject(parallel_subject_nodes)
          parallel_subjects = parallel_subject_nodes.map { |subject_node| build_subject(subject_node) }.compact
          # Moving type up from parallel subjects if they are all the same.
          move_type = parallel_subjects.uniq { |subject| subject[:type] }.size == 1
          type = move_type ? parallel_subjects.map { |subject| subject.delete(:type) }.compact.first : nil
          {
            parallelValue: parallel_subjects.presence,
            type: type
          }.compact.presence
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/AbcSize
        def build_subject(subject_node)
          return { valueAt: subject_node['xlink:href'] } if subject_node['xlink:href']

          attrs = common_attrs(subject_node)
          return subject_classification(subject_node, attrs) if subject_node.name == 'classification'

          if subject_node.elements.empty?
            unless subject_node[:valueURI]
              notifier.error('Subject has no children nodes', { subject: subject_node.to_s })
              return nil
            end
            notifier.warn('Subject has text', { subject: subject_node.to_s }) if subject_node.content.present?
          end

          children_nodes = subject_node.xpath('mods:*', mods: DESC_METADATA_NS).to_a.reject { |child_node| child_node.children.empty? && child_node.attributes.empty? }
          first_child_node = children_nodes.first

          if children_nodes.empty?
            attrs if subject_node[:valueURI]
          elsif temporal_range?(children_nodes)
            temporal_range(children_nodes, attrs)
          elsif children_nodes.size != 1
            if geo_code?(children_nodes)
              geo_code_and_terms(children_nodes, attrs)
            else
              structured_value(children_nodes, attrs)
            end
          elsif first_child_node.name == 'hierarchicalGeographic'
            hierarchical_geographic(first_child_node, attrs)
          else
            simple_item(first_child_node, attrs)
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/AbcSize

        def temporal_range?(children_nodes)
          children_nodes.all? { |node| node.name == 'temporal' && node['point'] }
        end

        def geo_code?(children_nodes)
          children_nodes.any? { |node| node.name == 'geographicCode' }
        end

        def common_attrs(subject)
          {
            displayLabel: subject[:displayLabel]
          }.tap do |attrs|
            source = {
              code: code_for(subject),
              uri: Authority.normalize_uri(subject[:authorityURI]),
              version: subject['edition']
            }.compact
            attrs[:source] = source unless source.empty?
            attrs[:uri] = ValueURI.sniff(subject[:valueURI], notifier)
            attrs[:encoding] = { code: subject[:encoding] } if subject[:encoding]
            language_script = LanguageScript.build(node: subject)
            attrs[:valueLanguage] = language_script if language_script
            attrs[:status] = 'primary' if subject['usage'] == 'primary'
          end.compact
        end

        def code_for(subject)
          code = Authority.normalize_code(subject[:authority], notifier)

          return nil if code.nil?

          notifier.warn('Subject has unknown authority code', { code: code }) unless SubjectAuthorityCodes::SUBJECT_AUTHORITY_CODES.include?(code)

          code
        end

        def structured_value(node_set, attrs)
          values = node_set.map { |node| simple_item(node) }.compact
          if values.present?
            Primary.adjust(values, 'genre', notifier, match_type: true)
            attrs = attrs.merge(structuredValue: values)
            adjust_source(attrs)
            adjust_lang(attrs)
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

        def adjust_lang(attrs)
          # If all values have same valueLanguage then move to subject.
          check_value_language = attrs[:structuredValue].first[:valueLanguage]
          return unless check_value_language && attrs[:structuredValue].all? { |value| value[:valueLanguage] == check_value_language }

          attrs[:valueLanguage] = check_value_language
          attrs[:structuredValue].each { |value| value.delete(:valueLanguage) }
        end

        def adjust_source(attrs)
          attrs.delete(:source) if remove_source?(attrs)

          # If attr has source, add to all values that have valueURI but no source.
          attrs[:structuredValue].each do |value|
            value[:source] ||= attrs[:source] if attrs[:source] && value[:uri]
          end
        end

        def remove_source?(attrs)
          # Remove source if no uri and all values have source and all are not same type
          return false if attrs[:uri]
          return false if attrs[:structuredValue].any? { |value| value[:source].nil? }

          types = attrs[:structuredValue].pluck(:type)
          return false unless types.any? { |type| type != types.first }

          true
        end

        def hierarchical_geographic(hierarchical_geographic_node, attrs)
          attrs = attrs.deep_merge(common_attrs(hierarchical_geographic_node))
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
          notifier.warn('No source given for classification value', value: subject_classification_node.text) unless attrs[:uri] || attrs.dig(:source, :code) || attrs.dig(:source, :uri)

          classification_attributes = {}.tap do |attributes|
            attributes[:type] = 'classification'
            attributes[:value] = subject_classification_node.text
            attributes[:displayLabel] = subject_classification_node[:displayLabel] if subject_classification_node[:displayLabel]
            attributes[:status] = 'primary' if subject_classification_node['usage'] == 'primary'
          end
          attrs.merge(classification_attributes)
        end

        # @return [Hash, NilClass]
        def simple_item(node, attrs = {})
          attrs = attrs.deep_merge(common_attrs(node))
          case node.name
          when 'name'
            name(node, attrs)
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

        def name(node, attrs)
          name_type = name_type_for_subject(node)
          attrs[:type] = name_type if name_type
          full_name = NameBuilder.build(name_elements: [node], notifier: notifier)
          return nil if full_name[:name].nil?

          name_attrs = if full_name[:name].size > 1
                         {
                           parallelValue: full_name[:name]
                         }
                       else
                         full_name[:name].first
                       end
          name_attrs[:note] = full_name[:role].map { |role| role.merge({ type: 'role' }) } if full_name[:role].present?
          name_attrs.merge(attrs)
        end

        def node_type_for(node)
          return NODE_TYPE.fetch(node.name) if NODE_TYPE.keys.include?(node.name)

          notifier.warn('Unexpected node type for subject', name: node.name)
          nil
        end

        def name_type_for_subject(node)
          name_type = node[:type]

          unless name_type
            notifier.warn('Subject contains a <name> element without a type attribute') unless node['xlink:href']
            return 'name'
          end

          return 'topic' if name_type.downcase == 'topic'

          Contributor::ROLES.fetch(name_type) if Contributor::ROLES.keys.include?(name_type)
        end

        def subject_nodes
          resource_element.xpath('mods:subject', mods: DESC_METADATA_NS) + resource_element.xpath('mods:classification', mods: DESC_METADATA_NS)
        end

        def temporal_range(children_nodes, attrs)
          attrs[:structuredValue] = children_nodes.select { |node| node.content.present? }.map do |node|
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
            subject_node.xpath('mods:cartographics/mods:coordinates', mods: DESC_METADATA_NS).map do |coordinate_node|
              coordinate = coordinate_node.content
              next nil if coordinate.blank?

              coordinate.delete_prefix('(').delete_suffix(')')
            end.compact
          end.flatten.compact.uniq

          coordinates.map { |coordinate| { value: coordinate, type: 'map coordinates' } }
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength

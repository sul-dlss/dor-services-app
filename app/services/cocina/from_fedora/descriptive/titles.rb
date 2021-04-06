# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps titles
      class Titles
        TYPES = {
          'nonSort' => 'nonsorting characters',
          'title' => 'main title',
          'subTitle' => 'subtitle',
          'partNumber' => 'part number',
          'partName' => 'part name',
          'date' => 'life dates',
          'given' => 'forename',
          'family' => 'surname',
          'uniform' => 'title'
        }.freeze

        PERSON_TYPE = 'name'

        NAME_TYPES = ['person', 'forename', 'surname', 'life dates'].freeze

        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [boolean] require_title notify if true and title is missing.
        # @param [Cocina::FromFedora::DataErrorNotifier] notifier
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, notifier:, require_title: true)
          new(resource_element: resource_element, notifier: notifier).build(require_title: require_title)
        end

        def initialize(resource_element:, notifier:)
          @resource_element = resource_element
          @notifier = notifier
        end

        def build(require_title: true)
          altrepgroup_title_info_nodes, other_title_info_nodes = AltRepGroup.split(nodes: resource_element.xpath('mods:titleInfo', mods: DESC_METADATA_NS))

          result = altrepgroup_title_info_nodes.map { |title_info_nodes| parallel(title_info_nodes) } \
            + simple_or_structured(other_title_info_nodes)
          Primary.adjust(result, 'title', notifier)

          notifier.error('Missing title') if result.empty? && require_title

          result
        end

        private

        attr_reader :resource_element, :notifier

        # @param [Nokogiri::XML::NodeSet] node_set the titleInfo elements in the parallel grouping
        def parallel(node_set)
          {
            parallelValue: simple_or_structured(node_set, display_types: display_types?(node_set))
          }.tap do |result|
            type = parallel_type(node_set)
            result[:type] = type if type && type != 'parallel'
          end
        end

        def display_types?(node_set)
          return false if node_set.all? { |node| node['type'] == 'translated' || node['usage'] == 'primary' }
          return false if node_set.all? { |node| node['type'] == 'uniform' }

          true
        end

        def parallel_type(node_set)
          # If both uniform, then uniform
          return 'uniform' if node_set.all? { |node| node[:type] == 'uniform' }
          # If none of these nodes are marked as primary or don't have a type, set the type to parallel
          return 'parallel' unless node_set.any? { |node| node['usage'] || !node['type'] }

          nil
        end

        def simple_or_structured(node_set, display_types: true)
          node_set.map do |node|
            if node['nameTitleGroup']
              structured_name(node: node, display_types: display_types)
            else
              attrs = TitleBuilder.build(title_info_element: node, notifier: notifier)
              attrs.present? ? attrs.merge(common_attributes(node, display_types: display_types)) : nil
            end
          end.compact
        end

        def structured_name(node:, display_types: true)
          name_node = resource_element.xpath("mods:name[@nameTitleGroup='#{node['nameTitleGroup']}']", mods: DESC_METADATA_NS).first

          structured_values = if name_node.nil?
                                notifier.warn('Name not found for title group')
                                []
                              else
                                NameBuilder.build(name_elements: [name_node], notifier: notifier)[:name]
                              end
          structured_values.each { |structured_value| structured_value[:type] = 'name' }
          {
            structuredValue: [
              { type: 'title' }.merge(TitleBuilder.build(title_info_element: node, notifier: notifier))
            ].concat(structured_values)
          }.merge(common_attributes(node, display_types: display_types))
        end

        # @param [Hash<Symbol,String>] value
        # @param [Nokogiri::XML::Element] title_info the titleInfo node
        # @param [Bool] display_types this is set to false in the case that it's a parallelValue and all are translations
        def common_attributes(title_info, display_types: true)
          {}.tap do |attrs|
            attrs[:status] = 'primary' if title_info['usage'] == 'primary'
            attrs[:type] = title_info['type'] if display_types && title_info['type']
            attrs[:type] = 'transliterated' if title_info['transliteration']
            attrs[:type] = 'supplied' if title_info['supplied'] == 'yes'

            source = {
              code: Authority.normalize_code(title_info[:authority], notifier),
              uri: Authority.normalize_uri(title_info[:authorityURI])
            }.compact
            attrs[:source] = source if source.present?
            attrs[:uri] = ValueURI.sniff(title_info[:valueURI], notifier)

            value_language = LanguageScript.build(node: title_info)
            attrs[:valueLanguage] = value_language if value_language
            attrs[:standard] = { value: title_info['transliteration'] } if title_info['transliteration']
            attrs[:displayLabel] = title_info['displayLabel']
          end.compact
        end
      end
    end
  end
end

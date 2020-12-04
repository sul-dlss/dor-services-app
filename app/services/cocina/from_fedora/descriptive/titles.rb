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
        # @param [boolean] require_title raise Cocina::Mapper::MissingTitle if true and title is missing.
        # @return [Hash] a hash that can be mapped to a cocina model
        # @raises [Mapper::MissingTitle]
        def self.build(resource_element:, require_title: true)
          new(resource_element: resource_element).build(require_title: require_title)
        end

        def initialize(resource_element:)
          @resource_element = resource_element
        end

        def build(require_title: true)
          title_infos_with_groups = resource_element.xpath('mods:titleInfo[@altRepGroup]', mods: DESC_METADATA_NS)
          grouped_title_infos = title_infos_with_groups.group_by { |node| node['altRepGroup'] }

          result = grouped_title_infos.map { |_k, node_set| parallel(node_set) }

          title_infos_without_groups = resource_element.xpath('mods:titleInfo[not(@altRepGroup)]', mods: DESC_METADATA_NS)
          result += simple_or_structured(title_infos_without_groups)

          raise Cocina::Mapper::MissingTitle if result.empty? && require_title

          result
        end

        private

        attr_reader :resource_element

        # @param [Nokogiri::XML::NodeSet] node_set the titleInfo elements in the parallel grouping
        def parallel(node_set)
          {
            parallelValue: simple_or_structured(node_set, display_types: display_types?(node_set))
          }.tap do |result|
            type = parallel_type(node_set)
            result[:type] = type if type
          end
        end

        def display_types?(node_set)
          return false if node_set.all? { |node| node['type'] == 'translated' }
          return false if node_set.all? { |node| node['type'] == 'uniform' }

          true
        end

        def parallel_type(node_set)
          # If both uniform, then uniform
          return 'uniform' if node_set.all? { |node| node[:type] == 'uniform' }
          # If none of these nodes are marked as primary, set the type to parallel
          return 'parallel' unless node_set.any? { |node| node['usage'] }

          nil
        end

        def simple_or_structured(node_set, display_types: true)
          node_set.map do |node|
            if node['nameTitleGroup']
              structured_name(node: node, display_types: display_types)
            else
              attrs = title_info_to_simple_or_structured(node)
              attrs.present? ? attrs.merge(common_attributes(node, display_types: display_types)) : nil
            end
          end.compact
        end

        # @param [Nokogiri::XML::Element] title_info the titleInfo node
        def title_info_to_simple_or_structured(title_info)
          # Find all the child nodes that have text
          return nil if title_info.children.empty?

          children = title_info.xpath('./*[child::node()[self::text()]]')
          if children.empty?
            Honeybadger.notify('[DATA ERROR] Empty title node', { tags: 'data_error' })
            return nil
          end

          # If a displayLabel only with no title text element
          # Note: this is an error condition,
          # exceptions documented at: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_value_dependencies.txt
          return {} if children.map(&:name) == []

          # Is this a basic title or a title with parts
          return simple_value(title_info) if children.map(&:name) == ['title'] || children.size == 1

          { structuredValue: structured_value(children), note: note(children) }.compact
        end

        # @param [Nokogiri::XML::Element] node the titleInfo node
        def simple_value(node)
          value = node.xpath('./mods:title', mods: DESC_METADATA_NS).text

          { value: value }
        end

        def structured_name(node:, display_types: true)
          name_node = node.xpath("//mods:name[@nameTitleGroup='#{node['nameTitleGroup']}']", mods: DESC_METADATA_NS).first
          structured_values = if name_node.nil?
                                Honeybadger.notify('[DATA ERROR] Name not found for title group', { tags: 'data_error' })
                                []
                              else
                                NameBuilder.build(name_element: name_node, add_default_type: true)[:name]
                              end
          structured_values.each { |structured_value| structured_value[:type] = 'name' }

          {
            structuredValue: [
              { type: 'title' }.merge(title_info_to_simple_or_structured(node))
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
              code: Authority.normalize_code(title_info[:authority]),
              uri: Authority.normalize_uri(title_info[:authorityURI])
            }.compact
            attrs[:source] = source if source.present?
            attrs[:uri] = title_info[:valueURI]

            value_language = LanguageScript.build(node: title_info)
            attrs[:valueLanguage] = value_language if value_language
            attrs[:standard] = { value: title_info['transliteration'] } if title_info['transliteration']
            attrs[:displayLabel] = title_info['displayLabel']
          end.compact
        end

        # @param [Nokogiri::XML::NodeSet] child_nodes the children of the titleInfo
        def structured_value(child_nodes)
          child_nodes.map do |node|
            { value: node.text, type: TYPES[node.name] }
          end
        end

        def note(child_nodes)
          unsortable = child_nodes.select { |node| node.name == 'nonSort' }
          return nil if unsortable.empty?

          count = unsortable.sum do |node|
            add = node.text.end_with?('-') || node.text.end_with?("'") ? 0 : 1
            node.text.size + add
          end
          [{
            "value": count.to_s,  # cast to String until cocina-models 0.40.0 is used. See https://github.com/sul-dlss/cocina-models/pull/146
            "type": 'nonsorting character count'
          }]
        end
      end
    end
  end
end

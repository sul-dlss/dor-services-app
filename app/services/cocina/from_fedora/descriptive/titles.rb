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

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        # @raises [Mapper::MissingTitle]
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          title_infos_with_groups = ng_xml.xpath('//mods:mods/mods:titleInfo[@altRepGroup]', mods: DESC_METADATA_NS)
          grouped_title_infos = title_infos_with_groups.group_by { |node| node['altRepGroup'] }

          result = grouped_title_infos.map { |_k, node_set| parallel(node_set) }

          title_infos_without_groups = ng_xml.xpath('//mods:mods/mods:titleInfo[not(@altRepGroup)]', mods: DESC_METADATA_NS)
          result += simple_or_structured(title_infos_without_groups)

          raise Cocina::Mapper::MissingTitle if result.empty?

          result
        end

        private

        attr_reader :ng_xml

        # @param [Nokogiri::XML::NodeSet] node_set the titleInfo elements in the parallel grouping
        def parallel(node_set)
          { parallelValue: simple_or_structured(node_set, display_types: display_types?(node_set)) }.tap do |result|
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
          node_set.map { |node| title_info_to_simple_or_structured(node, display_types: display_types) }.compact
        end

        # @param [Nokogiri::XML::Element] title_info the titleInfo node
        def title_info_to_simple_or_structured(title_info, display_types:)
          # Find all the child nodes that have text
          return nil if title_info.children.empty?

          children = title_info.xpath('./*[child::node()[self::text()]]')
          if children.empty?
            Honeybadger.notify('[DATA ERROR] Empty title node', { tags: 'data_error' })
            return nil
          end

          # If a displayLabel only with no title text element
          # Note: this is an error condintion,
          # exceptions documented at: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_value_dependencies.txt
          return with_attributes({}, title_info, display_types: display_types) if children.map(&:name) == []

          # Is this a basic title or a title with parts
          return simple_value(title_info, display_types: display_types) if children.map(&:name) == ['title']

          with_attributes({ structuredValue: structured_value(children) }, title_info, display_types: display_types)
        end

        # @param [Nokogiri::XML::Element] node the titleInfo node
        # @param [Bool] display_types this is set to false in the case that it's a parallelValue and all are translations
        def simple_value(node, display_types:)
          value = node.xpath('./mods:title', mods: DESC_METADATA_NS).text
          return structured_name(node: node, title: value, display_types: display_types) if node['nameTitleGroup']

          with_attributes({ value: value }, node, display_types: display_types)
        end

        def structured_name(node:, title:, display_types: true)
          # Dereference the name in a nameTitleGroup to create the value
          parts = node.xpath("//mods:name[@nameTitleGroup='#{node['nameTitleGroup']}']/mods:namePart", mods: DESC_METADATA_NS)

          vals = if parts.blank?
                   Honeybadger.notify('[DATA ERROR] Name not found for title group', { tags: 'data_error' })
                   []
                 else
                   parts.map { |part| { value: part.text, type: Contributor::NAME_PART.fetch(part['type'], PERSON_TYPE) } }
                 end

          with_attributes({ structuredValue: vals + [{ value: title, type: 'title' }] },
                          node,
                          display_types: display_types)
        end

        # @param [Hash<Symbol,String>] value
        # @param [Nokogiri::XML::Element] title_info the titleInfo node
        # @param [Bool] display_types this is set to false in the case that it's a parallelValue and all are translations
        def with_attributes(value, title_info, display_types: true)
          value.tap do |result|
            result[:status] = 'primary' if title_info['usage'] == 'primary'
            result[:type] = title_info['type'] if display_types && title_info['type']
            result[:type] = 'transliterated' if title_info['transliteration']
            result[:type] = 'supplied' if title_info['supplied'] == 'yes'

            result[:source] = { code: title_info[:authority] } if title_info['type'] == 'abbreviated' && title_info[:authority]
            result[:uri] = title_info[:valueURI] if title_info['valueURI']

            result[:valueLanguage] = language(title_info) if title_info['lang']
            result[:standard] = { value: title_info['transliteration'] } if title_info['transliteration']
            result[:displayLabel] = title_info['displayLabel'] if title_info['displayLabel']
          end
        end

        def language(title_info)
          { code: title_info['lang'], source: { code: 'iso639-2b' } }.tap do |result|
            result[:valueScript] = { code: title_info['script'], source: { code: 'iso15924' } } if title_info['script']
          end
        end

        # @param [Nokogiri::XML::NodeSet] child_nodes the children of the titleInfo
        def structured_value(child_nodes)
          new_nodes = child_nodes.map do |node|
            { value: node.text, type: TYPES[node.name] }
          end

          unsortable = child_nodes.select { |node| node.name == 'nonSort' }
          if unsortable.any?
            count = unsortable.sum do |node|
              add = node.text.end_with?('-') || node.text.end_with?("'") ? 0 : 1
              node.text.size + add
            end
            new_nodes << {
              "note": [
                {
                  "value": count.to_s,  # cast to String until cocina-models 0.40.0 is used. See https://github.com/sul-dlss/cocina-models/pull/146
                  "type": 'nonsorting character count'
                }
              ]
            }
          end

          new_nodes
        end
      end
    end
  end
end

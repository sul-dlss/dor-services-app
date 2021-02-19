# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps notes
      class Notes
        # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
        # @param [Cocina::FromFedora::Descriptive::DescriptiveBuilder] descriptive_builder
        # @param [String] purl
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(resource_element:, descriptive_builder: nil, purl: nil)
          new(resource_element: resource_element).build
        end

        def initialize(resource_element:)
          @resource_element = resource_element
        end

        def build
          abstracts + notes + table_of_contents + target_audience
        end

        private

        attr_reader :resource_element

        def abstracts
          all_abstract_nodes = resource_element.xpath('mods:abstract', mods: DESC_METADATA_NS).select { |node| note_present?(node) }
          altrepgroup_abstract_nodes, other_abstract_nodes = AltRepGroup.split(nodes: all_abstract_nodes)
          other_abstract_nodes.map { |node| common_note_for(node).merge({ type: 'summary' }) } + \
            altrepgroup_abstract_nodes.map { |parallel_nodes| parallel_abstract_for(parallel_nodes) }
        end

        def parallel_abstract_for(abstract_nodes)
          {
            type: 'summary',
            parallelValue: abstract_nodes.map { |node| common_note_for(node) }
          }
        end

        def common_note_for(node)
          {
            value: node.content.presence,
            displayLabel: node[:displayLabel].presence,
            type: node[:type],
            valueAt: node['xlink:href']
          }.tap do |attributes|
            value_language = LanguageScript.build(node: node)
            attributes[:valueLanguage] = value_language if value_language
            if node['ID']
              attributes[:identifier] = [
                {
                  value: node['ID'],
                  type: 'anchor'
                }
              ]
            end
          end.compact
        end

        def notes
          all_note_nodes = resource_element.xpath('mods:note', mods: DESC_METADATA_NS).select { |node| note_present?(node) && node[:type] != 'contact' }
          altrepgroup_note_nodes, other_note_nodes = AltRepGroup.split(nodes: all_note_nodes)
          other_note_nodes.map { |node| common_note_for(node) } + \
            altrepgroup_note_nodes.map { |parallel_nodes| parallel_note_for(parallel_nodes) }
        end

        def note_present?(node)
          node.text.present? || node['xlink:href']
        end

        def parallel_note_for(note_nodes)
          {
            parallelValue: note_nodes.map { |note_node| common_note_for(note_node) }
          }
        end

        def target_audience
          resource_element.xpath('mods:targetAudience', mods: DESC_METADATA_NS).map do |node|
            {
              type: 'target audience',
              value: node.content,
              displayLabel: node['displayLabel']
            }.tap do |attrs|
              attrs[:source] = { code: node[:authority] } if node[:authority]
            end.compact
          end.compact
        end

        def table_of_contents
          all_toc_nodes = resource_element.xpath('mods:tableOfContents', mods: DESC_METADATA_NS).select { |node| note_present?(node) }
          altrepgroup_toc_nodes, other_toc_nodes = AltRepGroup.split(nodes: all_toc_nodes)
          other_toc_nodes.map { |node| toc_for(node).merge({ type: 'table of contents' }) } + \
            altrepgroup_toc_nodes.map { |parallel_nodes| parallel_toc_for(parallel_nodes) }
        end

        def parallel_toc_for(toc_nodes)
          {
            type: 'table of contents',
            parallelValue: toc_nodes.map { |toc_node| toc_for(toc_node) }
          }
        end

        def toc_for(node)
          {
            displayLabel: node[:displayLabel].presence,
            valueAt: node['xlink:href']
          }.tap do |attributes|
            value_language = LanguageScript.build(node: node)
            attributes[:valueLanguage] = value_language if value_language
            value_parts = node.content.split(' -- ')
            if value_parts.size == 1
              attributes[:value] = node.content
            elsif value_parts.present?
              attributes[:structuredValue] = value_parts.map { |value_part| { value: value_part } }
            end
          end.compact
        end
      end
    end
  end
end

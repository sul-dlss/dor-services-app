# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps subject nodes from MODS to cocina
      class Subject
        NODE_TYPE = {
          'temporal' => 'time',
          'topic' => 'topic',
          'geographic' => 'place',
          'genre' => 'genre',
          'occupation' => 'occupation'
        }.freeze

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          subjects.map do |subject|
            node_set = subject.xpath('*')
            attrs = source_attrs(subject)

            next structured_value(node_set, attrs) if node_set.size != 1

            node = node_set.first
            next hierarchical_geographic(node, attrs) if node.name == 'hierarchicalGeographic'

            simple_item(node, attrs)
          end.compact
        end

        private

        attr_reader :ng_xml

        def source_attrs(subject, attrs = {})
          if subject[:valueURI]
            attrs[:source] = { code: subject[:authority], uri: subject[:authorityURI] }.compact
            attrs[:uri] = subject[:valueURI]
          elsif subject[:authority]
            attrs[:source] = { code: subject[:authority] }
          end
          attrs
        end

        def structured_value(node_set, attrs)
          values = node_set.map { |node| simple_item(node) }
          attrs.merge(structuredValue: values)
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

        def simple_item(node, attrs = {})
          attrs = source_attrs(node, attrs)
          case node.name
          when 'name'
            Contributor.name_parts(node, add_default_type: true).first.merge(type: 'person').merge(attrs)
          when 'titleInfo'
            query = node.xpath('mods:title', mods: DESC_METADATA_NS)
            attrs.merge(value: query.first.text, type: 'title')
          when 'geographicCode'
            attrs.merge(code: node.text, type: 'place', source: { code: node['authority'] })
          when 'cartographics'
            coords = node.xpath('mods:coordinates', mods: DESC_METADATA_NS).first
            return nil if coords.nil?

            attrs.merge(value: coords.text, type: 'map coordinates', encoding: { value: 'DMS' })
          else
            attrs.merge(value: node.text, type: NODE_TYPE.fetch(node.name))
          end
        end

        def subjects
          ng_xml.xpath('//mods:subject', mods: DESC_METADATA_NS)
        end
      end
    end
  end
end

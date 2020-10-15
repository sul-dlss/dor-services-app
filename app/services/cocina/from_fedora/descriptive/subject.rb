# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps subject nodes from MODS to cocina
      class Subject
        NODE_TYPE = {
          'temporal' => 'time',
          'topic' => 'topic',
          'geographic' => 'place'
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
            case node_set.size
            when 1
              simple_item(node_set.first, attrs)
            else
              structured_value(node_set, attrs)
            end
          end
        end

        private

        attr_reader :ng_xml

        def source_attrs(subject, attrs = {})
          if subject[:valueURI]
            attrs[:source] = { code: subject[:authority], uri: subject[:authorityURI] }
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

        def simple_item(node, attrs = {})
          attrs = source_attrs(node, attrs)
          if node.name == 'name'
            query = node.xpath('mods:namePart', mods: DESC_METADATA_NS)
            attrs.merge(value: query.first.text, type: 'person')
          elsif node.name == 'geographicCode'
            attrs.merge(code: node.text, type: 'place', source: { code: node['authority'] })
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

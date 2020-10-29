# frozen_string_literal: true

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
            attrs = source_attrs(subject)
            node_set = subject.xpath('*')
            next subject_classification(subject, attrs) if subject.name == 'classification'

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
            attrs[:source] = {}.tap do |source|
              source[:code] = subject[:authority]
              source[:version] = format_edition(subject[:edition]) if subject[:edition]
            end
          end
          attrs
        end

        def structured_value(node_set, attrs)
          values = node_set.map { |node| simple_item(node) }.compact
          attrs.merge(structuredValue: values) if values.present?
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
          attrs = source_attrs(node, attrs)
          case node.name
          when 'name'
            if node[:type]
              attrs[:type] = Contributor::ROLES.fetch(node[:type])
            else
              Honeybadger.notify('Notice: Subject has <name> with no type attribute within <subject>')
            end
            Contributor.name_parts(node, add_default_type: true).first.merge(attrs)
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
          subject_node = ng_xml.xpath('//mods:subject', mods: DESC_METADATA_NS)
          return subject_node unless classification

          subject_node << classification
        end

        def classification
          ng_xml.xpath('//mods:classification', mods: DESC_METADATA_NS).first
        end

        def format_edition(edition)
          "#{edition.to_i.ordinalize} edition"
        end
      end
    end
  end
end

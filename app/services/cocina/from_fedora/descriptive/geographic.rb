# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS extension displayLabel geo to cocina descriptive extension
      # rubocop:disable Metrics/ClassLength
      class Geographic
        NAMESPACE = {
          'mods' => DESC_METADATA_NS,
          'dc' => DUBLIN_CORE_NS,
          'rdf' => RDF_NS,
          'gmd' => GMD_NS,
          'gml' => GML_NS
        }.freeze

        # Directional Constants for GEO
        SOUTH = 'south'
        WEST = 'west'
        NORTH = 'north'
        EAST = 'east'

        # Geo Extention Constants
        BOUNDING_BOX_COORDS = 'bounding box coordinates'
        COVERAGE = 'coverage'
        DATA_FORMAT = 'data format'
        DCMI_VOCAB = { value: 'DCMI Type Vocabulary' }.freeze
        DECIMAL_ENCODING = { value: 'decimal' }.freeze
        FORMAT_DELIM = '; format='
        IANA_TERMS = { value: 'IANA media type terms' }.freeze
        LANGUAGE = { code: 'eng' }.freeze
        MEDIA_TYPE = 'media type'
        POINT_COORDS = 'point coordinates'
        TYPE = 'type'

        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          return unless description

          [{}.tap do |extension|
            extension[:form] = build_form.flatten if build_form
            extension[:subject] = build_subject
          end.compact]
        end

        private

        attr_reader :ng_xml

        def build_form
          return unless format

          [].tap do |form|
            form << { value: format[:text], type: MEDIA_TYPE, source: IANA_TERMS }
            form << build_type
          end
        end

        def build_type
          return { value: type, type: MEDIA_TYPE, source: DCMI_VOCAB } if type == 'Image'

          [{ value: format[:format], type: DATA_FORMAT }, { value: type, type: TYPE }]
        end

        def build_subject
          return [build_subject_for_center_point] unless centerpoint.empty?
          return build_subject_for_bounding_box unless envelope.empty?
        end

        def build_subject_for_center_point
          {
            structuredValue: [centerpoint_latitude, centerpoint_longitude],
            type: POINT_COORDS,
            encoding: DECIMAL_ENCODING
          }
        end

        def build_subject_for_bounding_box
          [].tap do |subject|
            subject << structure_map
            coverage_map.map { |block| subject << block } unless coverage.empty?
          end
        end

        def structure_map
          {}.tap do |structure|
            structure[:structuredValue] = bounding_box_coordinates
            structure[:type] = BOUNDING_BOX_COORDS
            structure[:encoding] = DECIMAL_ENCODING
            structure[:standard] = { code: standard } if standard
          end
        end

        def coverage_map
          coverage.map do |data|
            title = data.attr('dc:title')
            uri = data.attr('rdf:resource')
            {}.tap do |coverage_for|
              coverage_for[:value] = title if title
              coverage_for[:type] = COVERAGE
              coverage_for[:valueLanguage] = LANGUAGE
              coverage_for[:uri] = uri if uri.present?
            end
          end
        end

        def bounding_box_coordinates
          [WEST, SOUTH, EAST, NORTH].map { |dir| boundary_position(dir) }
        end

        def description
          @description ||= ng_xml.xpath('//mods:mods/mods:extension/rdf:RDF/rdf:Description', NAMESPACE).first
        end

        def centerpoint
          description.xpath('//gmd:centerPoint/gml:Point/gml:pos', NAMESPACE).text.split
        end

        def centerpoint_latitude
          { value: centerpoint.first, type: 'latitude' }
        end

        def centerpoint_longitude
          { value: centerpoint.last, type: 'longitude' }
        end

        def coverage
          description.xpath('//dc:coverage', NAMESPACE)
        end

        def envelope
          description.xpath('//gml:boundedBy/gml:Envelope', NAMESPACE)
        end

        def format
          return unless description

          text, format = description.xpath('//dc:format', NAMESPACE).text.split(FORMAT_DELIM)
          @format ||= { text: text, format: format }
        end

        def lower_left_corner
          envelope.xpath('//gml:lowerCorner', NAMESPACE).text.split
        end

        def upper_right_corner
          envelope.xpath('//gml:upperCorner', NAMESPACE).text.split
        end

        def boundaries
          {
            SOUTH => lower_left_corner.last,
            WEST => lower_left_corner.first,
            NORTH => upper_right_corner.last,
            EAST => upper_right_corner.first
          }
        end

        def boundary_position(direction)
          { value: boundaries[direction], type: direction }
        end

        def standard
          envelope.attr('srsName')&.value
        end

        def type
          @type = description.xpath('//dc:type', NAMESPACE).text
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end

# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps MODS extension displayLabel geo to cocina descriptive extension
      class GeoExtension
        NAMESPACE = {
          'mods' => DESC_METADATA_NS,
          'dc' => DUBLIN_CORE_NS,
          'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
          'gmd' => 'http://www.isotc211.org/2005/gmd',
          'gml' => 'http://www.opengis.net/gml/3.2/'
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
          {}.tap do |extension|
            extension[:form] = build_form.flatten
            extension[:subject] = build_subject
          end.compact
        end

        private

        attr_reader :ng_xml

        def build_form
          [].tap do |form|
            form << { value: format[:text], type: 'media type', source: { value: 'IANA media type terms' } }
            form << case type
                    when 'Image'
                      build_image_type
                    else
                      [{ value: format[:format], type: 'data format' }, { value: type, type: 'type' }]
                    end
          end
        end

        def rdf_descriptive
          @rdf_descriptive ||= ng_xml.xpath('//mods:mods/mods:extension/rdf:RDF/rdf:Description', NAMESPACE).first
        end

        def build_form_format
          format = rdf_descriptive.xpath('//dc:format', NAMESPACE)
          {
            value: format.text,
            type: 'media type',
            source: {
              value: 'IANA media type terms'
            }
          }
        end

        def format
          text, format = rdf_descriptive.xpath('//dc:format', NAMESPACE).text.split('; format=')
          @format ||= { text: text, format: format }
        end

        def type
          @type = rdf_descriptive.xpath('//dc:type', NAMESPACE).text
        end

        def build_form_type
          [build_media_type, build_image_type]
        end

        def build_media_type
          {
            value: format[:text],
            type: 'media type',
            source: { value: 'IANA media type terms' }
          }
        end

        def build_image_type
          {
            value: type,
            type: 'media type',
            source: { value: 'DCMI Type Vocabulary' }
          }
        end

        def build_shapefile_type; end

        def build_subject
          return [build_subject_for_center_point] unless rdf_descriptive.xpath('//gmd:centerPoint', NAMESPACE).empty?
          return build_subject_for_bounding_box unless rdf_descriptive.xpath('//gml:boundedBy', NAMESPACE).empty?
        end

        def build_subject_for_center_point
          subject = rdf_descriptive.xpath('//gmd:centerPoint/gml:Point/gml:pos', NAMESPACE)
          {
            structuredValue: [
              {
                value: subject.text.split.first,
                type: 'latitude'
              },
              {
                value: subject.text.split.last,
                type: 'longitude'
              }
            ],
            type: 'point coordinates',
            encoding: {
              value: 'decimal'
            }
          }
        end

        def build_subject_for_bounding_box
          standard = rdf_descriptive.xpath('//gml:boundedBy/gml:Envelope', NAMESPACE).attr('srsName')
          coverage = rdf_descriptive.xpath('//dc:coverage', NAMESPACE)
          lower_corner = rdf_descriptive.xpath('//gml:boundedBy/gml:Envelope/gml:lowerCorner', NAMESPACE)
          upper_corner = rdf_descriptive.xpath('//gml:boundedBy/gml:Envelope/gml:upperCorner', NAMESPACE)

          coordinates = [
            {
              value: lower_corner.text.split.first,
              type: 'west'
            },
            {
              value: lower_corner.text.split.last,
              type: 'south'
            },
            {
              value: upper_corner.text.split.first,
              type: 'east'
            },
            {
              value: upper_corner.text.split.last,
              type: 'north'
            }
          ]

          [].tap do |subject|
            subject << {}.tap do |structure|
              structure[:structuredValue] = coordinates
              structure[:type] = 'bounding box coordinates'
              structure[:encoding] = { value: 'decimal' }
              structure[:standard] = { code: standard.value, type: 'coordinate reference system' } if standard
            end

            next if coverage.empty?

            coverage.each do |coverage_block|
              title = coverage_block.attr('dc:title')
              uri = coverage_block.attr('rdf:resource')
              subject << {}.tap do |coverage_for|
                coverage_for[:value] = title if title
                coverage_for[:type] = 'coverage'
                coverage_for[:language] = { code: 'eng' }
                coverage_for[:uri] = uri unless uri.blank?
              end
            end
          end
        end

        def standard
          {
            code: rdf_descriptive.xpath('//gml:boundedBy/gml:Envelope[@gml:srsName]', NAMESPACE),
            type: 'coordinate reference system'
          }
        end
      end
    end
  end
end

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
            extension[:form] = build_form
            extension[:subject] = [build_subject]
          end.compact
        end

        private

        attr_reader :ng_xml

        def build_form
          [].tap do |form|
            form << build_form_format
            form << build_form_type
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

        def build_form_type
          type = rdf_descriptive.xpath('//dc:type', NAMESPACE)
          {
            value: type.text,
            type: 'media type',
            source: {
              value: 'DCMI Type Vocabulary'
            }
          }
        end

        def build_subject
          return build_subject_for_center_point unless rdf_descriptive.xpath('//gmd:centerPoint', NAMESPACE).empty?
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
          lower_corner = rdf_descriptive.xpath('//gml:boundedBy/gml:Envelope/gml:lowerCorner', NAMESPACE)
          upper_corner = rdf_descriptive.xpath('//gml:boundedBy/gml:Envelope/gml:upperCorner', NAMESPACE)
          {
            structuredValue: [
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
            ],
            type: "bounding box coordinates",
            encoding: {
              value: "decimal"
            }
          }
        end
      end
    end
  end
end

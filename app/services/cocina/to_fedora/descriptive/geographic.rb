# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps geo extension from cocina to MODS
      class Geographic
        TYPE_REGEX = /^type$/.freeze
        MEDIA_REGEX = /^media type$/.freeze
        DATA_FORMAT_REGEX = /^data format$/.freeze

        ABOUT_URI_PREFIX = 'http://purl.stanford.edu/'

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] geos
        def self.write(xml:, geos:, druid:)
          new(xml: xml, geos: geos, druid: druid).write
        end

        def initialize(xml:, geos:, druid:)
          @xml = xml
          @geos = geos
          @druid = druid
        end

        def write
          return if geos.blank?

          geos.map do |geo|
            attributes = {}
            attributes[:displayLabel] = 'geo'
            xml.extension attributes do
              xml['rdf'].RDF(format_namespace(geo)) do
                xml['rdf'].Description('rdf:about' => about(druid)) do
                  add_format(extract_format(geo))
                  add_type(extract_type(geo))
                  add_content(geo)
                end
              end
            end
          end
        end

        private

        attr_reader :xml, :geos, :druid

        def format_namespace(geo)
          namespace = {
            'xmlns:gml' => 'http://www.opengis.net/gml/3.2/',
            'xmlns:dc' => 'http://purl.org/dc/elements/1.1/'
          }

          namespace['xmlns:gmd'] = 'http://www.isotc211.org/2005/gmd' if geo.subject&.first&.type&.include? 'point coordinates'

          namespace
        end

        def extract_format(geo)
          media_type = geo.form.find { |form| form.type.match(MEDIA_REGEX) && form[:value] != 'Image' }
          data_format = geo.form.find { |form| form.type.match(DATA_FORMAT_REGEX) }

          return "#{media_type.value}; format=#{data_format.value}" if data_format && media_type

          media_type&.value
        end

        def extract_type(geo)
          type = geo[:form].find { |form| form[:type].match(TYPE_REGEX) || (form[:type].match(MEDIA_REGEX) && form[:value] == 'Image') }
          return type[:value] if type

          nil
        end

        def about(druid)
          "#{ABOUT_URI_PREFIX}#{druid.delete_prefix('druid:')}"
        end

        def add_format(data)
          xml['dc'].format data if data
        end

        def add_type(type)
          xml['dc'].type type if type
        end

        def add_content(geo)
          type = geo.subject&.first&.type
          case type
          when 'point coordinates'
            add_centerpoint(geo)
          when 'bounding box coordinates'
            add_bounding_box(geo)
            add_coverage(geo)
          end
        end

        def add_centerpoint(geo)
          lat = geo.subject.first.structuredValue.find { |point| point.type.include? 'latitude' }.value
          long = geo.subject.first.structuredValue.find { |point| point.type.include? 'longitude' }.value
          xml['gmd'].centerPoint do
            xml['gml'].Point do
              xml['gml'].pos "#{lat} #{long}"
            end
          end
        end

        def add_bounding_box(geo)
          standard_tag = {}
          standard = geo.subject.first.standard
          standard_tag = { 'gml:srsName' => standard[:code] } if standard
          xml['gml'].boundedBy do
            xml['gml'].Envelope(standard_tag) do
              bounding_box_coordinates = bounding_box_coordinates_for(geo)
              xml['gml'].lowerCorner "#{bounding_box_coordinates[:west]} #{bounding_box_coordinates[:south]}"
              xml['gml'].upperCorner "#{bounding_box_coordinates[:east]} #{bounding_box_coordinates[:north]}"
            end
          end
        end

        def bounding_box_coordinates_for(geo)
          {}.tap do |coords|
            geo.subject.first.structuredValue.each do |direction|
              coords[direction.type.to_sym] = direction.value
            end
          end
        end

        def add_coverage(geo)
          coverage = geo[:subject].find_all { |sub| sub[:type].include? 'coverage' }
          return nil if coverage.empty?

          coverage.map do |data|
            coverage_attributes = {}
            coverage_attributes['rdf:resource'] = data.uri if data.uri
            coverage_attributes['dc:language'] = data.valueLanguage.code if data.valueLanguage&.code
            coverage_attributes['dc:title'] = data.value if data.value
            xml['dc'].coverage coverage_attributes
          end
        end
      end
    end
  end
end

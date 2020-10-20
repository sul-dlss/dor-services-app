# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps geo extension from cocina to MODS
      class Geographic
        DEFAULT_FORMAT = 'image/jpeg'
        DEFAULT_TYPE = 'Image'
        TYPE_REGEX = /^type$/.freeze
        MEDIA_REGEX = /^media type$/.freeze
        DATA_FORMAT_REGEX = /^data format$/.freeze

        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] geo
        def self.write(xml:, geo:)
          new(xml: xml, geo: geo).write
        end

        def initialize(xml:, geo:)
          @xml = xml
          @geo = geo
        end

        def write
          return if geo.nil?

          attributes = {}
          attributes[:displayLabel] = 'geo'
          xml.extension attributes do
            xml['rdf'].RDF(format_namespace(geo[:subject].first[:type])) do
              # REVIST: Need the druid to include rdf:about
              # xml['rdf'].Description('rdf:about' => 'http://www.stanford.edu/kk138ps4721') do
              xml['rdf'].Description do
                add_format(extract_format)
                add_type(extract_type)
                add_content
              end
            end
          end
        end

        private

        attr_reader :xml, :geo

        def format_namespace(type)
          namespace = {
            'xmlns:gml' => 'http://www.opengis.net/gml/3.2/',
            'xmlns:dc' => 'http://purl.org/dc/elements/1.1/'
          }

          namespace['xmlns:gmd'] = 'http://www.isotc211.org/2005/gmd' if type.include? 'point coordinates'

          namespace
        end

        def extract_format
          media_type = geo[:form].find { |form| form[:type].match(MEDIA_REGEX) }
          data_format = geo[:form].find { |form| form[:type].match(DATA_FORMAT_REGEX) }

          return "#{media_type[:value]}; format=#{data_format[:value]}" if data_format

          DEFAULT_FORMAT
        end

        def extract_type
          type = geo[:form].find { |form| form[:type].match(TYPE_REGEX) }
          return type[:value] if type

          DEFAULT_TYPE
        end

        def add_format(data)
          xml['dc'].format data
        end

        def add_type(type)
          xml['dc'].type type
        end

        def add_content
          type = geo[:subject].first[:type]
          case type
          when 'point coordinates'
            add_centerpoint
          when 'bounding box coordinates'
            add_bounding_box
            add_coverage
          end
        end

        def add_centerpoint
          lat = geo[:subject].first[:structuredValue].find { |point| point[:type].include? 'latitude' }[:value]
          long = geo[:subject].first[:structuredValue].find { |point| point[:type].include? 'longitude' }[:value]
          xml['gmd'].centerPoint do
            xml['gml'].Point('gml:id' => 'ID') do
              xml['gml'].pos "#{lat} #{long}"
            end
          end
        end

        def add_bounding_box
          standard_tag = {}
          standard = geo[:subject].first[:standard]
          standard_tag = { 'gml:srsName' => standard[:code] } if standard
          xml['gml'].boundedBy do
            xml['gml'].Envelope(standard_tag) do
              xml['gml'].lowerCorner "#{bounding_box_coordinates[:west]} #{bounding_box_coordinates[:south]}"
              xml['gml'].upperCorner "#{bounding_box_coordinates[:east]} #{bounding_box_coordinates[:north]}"
            end
          end
        end

        def bounding_box_coordinates
          @bounding_box_coordinates ||= {}.tap do |coords|
            geo[:subject].first[:structuredValue].each do |direction|
              coords[direction[:type].to_sym] = direction[:value]
            end
          end
        end

        def add_coverage
          coverage = geo[:subject].find_all { |sub| sub[:type].include? 'coverage' }
          return nil if coverage.empty?

          coverage.map do |data|
            coverage_attributes = {
              'rdf:resource' => data[:uri],
              'dc:language' => data[:valueLanguage][:code],
              'dc:title' => data[:value]
            }
            xml['dc'].coverage coverage_attributes
          end
        end
      end
    end
  end
end

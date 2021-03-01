# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Geographic do
  subject(:xml) { writer.to_xml }

  let(:geos) { [geo] }
  let(:druid) { 'druid:aa666bb1234' }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xmlns:rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, geos: geos, druid: druid)
      end
    end
  end

  context 'when geo is nil' do
    let(:geos) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'with a bounding box from a polygon shapefile converted from ISO 19139 missing standard' do
    let(:geo) do
      Cocina::Models::DescriptiveGeographicMetadata.new(
        form: [
          {
            value: 'application/x-esri-shapefile',
            type: 'media type',
            source: {
              value: 'IANA media type terms'
            }
          },
          {
            value: 'Shapefile',
            type: 'data format'
          },
          {
            value: 'Dataset#Polygon',
            type: 'type'
          }
        ],
        subject: [
          {
            structuredValue: [
              {
                value: '-119.667',
                type: 'west'
              },
              {
                value: '-89.8842',
                type: 'south'
              },
              {
                value: '168.463',
                type: 'east'
              },
              {
                value: '-66.6497',
                type: 'north'
              }
            ],
            type: 'bounding box coordinates',
            encoding: {
              value: 'decimal'
            }
          },
          {
            value: 'Antarctica',
            type: 'coverage',
            valueLanguage: {
              code: 'eng'
            },
            uri: 'http://sws.geonames.org/6255152/'
          }
        ]
      )
    end

    it 'builds the cocina data structure' do
      # TODO:  rdf:about="http://purl.stanford.edu/xy581jd9710"
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="http://purl.stanford.edu/aa666bb1234">
                <dc:format>application/x-esri-shapefile; format=Shapefile</dc:format>
                <dc:type>Dataset#Polygon</dc:type>
                <gml:boundedBy>
                  <gml:Envelope>
                    <gml:lowerCorner>-119.667 -89.8842</gml:lowerCorner>
                    <gml:upperCorner>168.463 -66.6497</gml:upperCorner>
                  </gml:Envelope>
                </gml:boundedBy>
                <dc:coverage rdf:resource="http://sws.geonames.org/6255152/" dc:language="eng" dc:title="Antarctica"/>
              </rdf:Description>
            </rdf:RDF>
          </extension>
      XML
    end
  end

  context 'when a polygon shapefile without subject' do
    let(:geo) do
      Cocina::Models::DescriptiveGeographicMetadata.new(
        form: [
          {
            value: 'application/x-esri-shapefile',
            type: 'media type',
            source: {
              value: 'IANA media type terms'
            }
          },
          {
            value: 'Shapefile',
            type: 'data format'
          },
          {
            value: 'Dataset#Polygon',
            type: 'type'
          }
        ]
      )
    end

    it 'builds the cocina data structure' do
      # TODO:  rdf:about="http://purl.stanford.edu/xy581jd9710"
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="http://purl.stanford.edu/aa666bb1234">
                <dc:format>application/x-esri-shapefile; format=Shapefile</dc:format>
                <dc:type>Dataset#Polygon</dc:type>
              </rdf:Description>
            </rdf:RDF>
          </extension>
      XML
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::GeoExtension do
  subject(:build) { described_class.build(ng_xml) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with extension displayLabel geo for point coordinates' do
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:gmd="http://www.isotc211.org/2005/gmd">
            <rdf:Description rdf:about="http://www.stanford.edu/kk138ps4721">
              <dc:format>image/jpeg</dc:format>
              <dc:type>Image</dc:type>
              <gmd:centerPoint>
                <gml:Point gml:id="ID">
                  <gml:pos>41.893367 12.483736</gml:pos>
                </gml:Point>
              </gmd:centerPoint>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq({
          "form": [
            {
              "value": "image/jpeg",
              "type": "media type",
              "source": {
                "value": "IANA media type terms"
              }
            },
            {
              "value": "Image",
              "type": "media type",
              "source": {
                "value": "DCMI Type Vocabulary"
              }
            }
          ],
          "subject": [
            {
              "structuredValue": [
                {
                  "value": "41.893367",
                  "type": "latitude"
                },
                {
                  "value": "12.483736",
                  "type": "longitude"
                }
              ],
              "type": "point coordinates",
              "encoding": {
                "value": "decimal"
              }
            }
          ]
        })
    end
  end

  context 'with extension displayLabel geo for a bounding box' do
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <rdf:Description rdf:about="http://purl.stanford.edu/cw222pt0426">
              <dc:format>image/jpeg</dc:format>
              <dc:type>Image</dc:type>
              <gml:boundedBy>
                <gml:Envelope>
                  <gml:lowerCorner>-122.191292 37.4063388</gml:lowerCorner>
                  <gml:upperCorner>-122.149475 37.4435369</gml:upperCorner>
                </gml:Envelope>
              </gml:boundedBy>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq({ form: [
          {
            value: "image/jpeg",
            type: "media type",
            source: {
              value: "IANA media type terms"
            }
          },
          {
            value: "Image",
            type: "media type",
            source: {
              value: "DCMI Type Vocabulary"
            }
          }
        ],
        subject: [
          {
            structuredValue: [
              {
                value: "-122.191292",
                type: "west"
              },
              {
                value: "37.4063388",
                type: "south"
              },
              {
                value: "-122.149475",
                type: "east"
              },
              {
                value: "37.4435369",
                type: "north"
              }
            ],
            type: "bounding box coordinates",
            encoding: {
              value: "decimal"
            }
          }
        ]
      })
    end
  end

  # 3. Bounding box for polygon shapefile converted from ISO 19139
  xcontext '' do
    let(:xml) do
      <<~XML
      XML
    end

    it 'builds teh cocina data structure' do
    end
  end

  # 4. Bounding box for point shapefile converted from ISO 19139
  xcontext '' do
    let(:xml) do
      <<~XML
      XML
    end

    it 'builds teh cocina data structure' do
    end
  end

  # 5. Bounding box for line shapefile converted from ISO 19139
  xcontext '' do
    let(:xml) do
      <<~XML
      XML
    end

    it 'builds teh cocina data structure' do
    end
  end

  # 6. Raster image converted from ISO 19139
  xcontext '' do
    let(:xml) do
      <<~XML
      XML
    end

    it 'builds teh cocina data structure' do
    end
  end

  # 7. Geonames and unauthorized subject terms
  xcontext '' do
    let(:xml) do
      <<~XML
      XML
    end

    it 'builds teh cocina data structure' do
    end
  end
end

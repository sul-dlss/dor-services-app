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

  context 'with point coordinates' do
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
                                "value": 'image/jpeg',
                                "type": 'media type',
                                "source": {
                                  "value": 'IANA media type terms'
                                }
                              },
                              {
                                "value": 'Image',
                                "type": 'media type',
                                "source": {
                                  "value": 'DCMI Type Vocabulary'
                                }
                              }
                            ],
                            "subject": [
                              {
                                "structuredValue": [
                                  {
                                    "value": '41.893367',
                                    "type": 'latitude'
                                  },
                                  {
                                    "value": '12.483736',
                                    "type": 'longitude'
                                  }
                                ],
                                "type": 'point coordinates',
                                "encoding": {
                                  "value": 'decimal'
                                }
                              }
                            ]
                          })
    end
  end

  context 'with a basic bounding box' do
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
                              value: 'image/jpeg',
                              type: 'media type',
                              source: {
                                value: 'IANA media type terms'
                              }
                            },
                            {
                              value: 'Image',
                              type: 'media type',
                              source: {
                                value: 'DCMI Type Vocabulary'
                              }
                            }
                          ],
                            subject: [
                              {
                                structuredValue: [
                                  {
                                    value: '-122.191292',
                                    type: 'west'
                                  },
                                  {
                                    value: '37.4063388',
                                    type: 'south'
                                  },
                                  {
                                    value: '-122.149475',
                                    type: 'east'
                                  },
                                  {
                                    value: '37.4435369',
                                    type: 'north'
                                  }
                                ],
                                type: 'bounding box coordinates',
                                encoding: {
                                  value: 'decimal'
                                }
                                # standard: {
                                #   code: [],
                                #   type: 'coordinate reference system'
                                # }
                              }
                            ] })
    end
  end

  # 3. Bounding box for polygon shapefile converted from ISO 19139
  context 'with a bounding box from a polygon shapefile converted from ISO 19139' do
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <rdf:Description rdf:about="http://purl.stanford.edu/xy581jd9710">
              <dc:format>application/x-esri-shapefile; format=Shapefile</dc:format>
              <dc:type>Dataset#Polygon</dc:type>
              <gml:boundedBy>
                <gml:Envelope gml:srsName="EPSG:4326">
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

    it 'builds the cocina data structure' do
      expect(build).to eq({
                            "form": [
                              {
                                "value": 'application/x-esri-shapefile',
                                "type": 'media type',
                                "source": {
                                  "value": 'IANA media type terms'
                                }
                              },
                              {
                                "value": 'Shapefile',
                                "type": 'data format'
                              },
                              {
                                "value": 'Dataset#Polygon',
                                "type": 'type'
                              }
                            ],
                            "subject": [
                              {
                                "structuredValue": [
                                  {
                                    "value": '-119.667',
                                    "type": 'west'
                                  },
                                  {
                                    "value": '-89.8842',
                                    "type": 'south'
                                  },
                                  {
                                    "value": '168.463',
                                    "type": 'east'
                                  },
                                  {
                                    "value": '-66.6497',
                                    "type": 'north'
                                  }
                                ],
                                "type": 'bounding box coordinates',
                                "encoding": {
                                  "value": 'decimal'
                                },
                                "standard": {
                                  "code": 'EPSG:4326',
                                  "type": 'coordinate reference system'
                                }
                              },
                              {
                                "value": 'Antarctica',
                                "type": 'coverage',
                                "language": {
                                  "code": 'eng'
                                },
                                "uri": 'http://sws.geonames.org/6255152/'
                              }
                            ]
                          })
    end
  end

  # 4. Bounding box for point shapefile converted from ISO 19139
  context 'with a bounding box from a point shapefile converted from ISO 19139' do
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <rdf:Description rdf:about="http://purl.stanford.edu/gq515vq0921">
              <dc:format>application/x-esri-shapefile; format=Shapefile</dc:format>
              <dc:type>Dataset#Point</dc:type>
              <gml:boundedBy>
                <gml:Envelope gml:srsName="EPSG:4326">
                  <gml:lowerCorner>-123.526676 36.896342</gml:lowerCorner>
                  <gml:upperCorner>-121.219649 38.856011</gml:upperCorner>
                </gml:Envelope>
              </gml:boundedBy>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq({
                            "form": [
                              {
                                "value": 'application/x-esri-shapefile',
                                "type": 'media type',
                                "source": {
                                  "value": 'IANA media type terms'
                                }
                              },
                              {
                                "value": 'Shapefile',
                                "type": 'data format'
                              },
                              {
                                "value": 'Dataset#Point',
                                "type": 'type'
                              }
                            ],
                            "subject": [
                              {
                                "structuredValue": [
                                  {
                                    "value": '-123.526676',
                                    "type": 'west'
                                  },
                                  {
                                    "value": '36.896342',
                                    "type": 'south'
                                  },
                                  {
                                    "value": '-121.219649',
                                    "type": 'east'
                                  },
                                  {
                                    "value": '38.856011',
                                    "type": 'north'
                                  }
                                ],
                                "type": 'bounding box coordinates',
                                "encoding": {
                                  "value": 'decimal'
                                },
                                "standard": {
                                  "code": 'EPSG:4326',
                                  "type": 'coordinate reference system'
                                }
                              }
                            ]
                          })
    end
  end

  # 5. Bounding box for line shapefile converted from ISO 19139
  context 'with a bounding box from a line shapefile converted from ISO 19139' do
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <rdf:Description rdf:about="http://purl.stanford.edu/nr717dp9096">
              <dc:format>application/x-esri-shapefile; format=Shapefile</dc:format>
              <dc:type>Dataset#LineString</dc:type>
              <gml:boundedBy>
                <gml:Envelope gml:srsName="EPSG:4326">
                  <gml:lowerCorner>19.406906 40.466388</gml:lowerCorner>
                  <gml:upperCorner>20.645261 42.337442</gml:upperCorner>
                </gml:Envelope>
              </gml:boundedBy>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq({
                            "form": [
                              {
                                "value": 'application/x-esri-shapefile',
                                "type": 'media type',
                                "source": {
                                  "value": 'IANA media type terms'
                                }
                              },
                              {
                                "value": 'Shapefile',
                                "type": 'data format'
                              },
                              {
                                "value": 'Dataset#LineString',
                                "type": 'type'
                              }
                            ],
                            "subject": [
                              {
                                "structuredValue": [
                                  {
                                    "value": '19.406906',
                                    "type": 'west'
                                  },
                                  {
                                    "value": '40.466388',
                                    "type": 'south'
                                  },
                                  {
                                    "value": '20.645261',
                                    "type": 'east'
                                  },
                                  {
                                    "value": '42.337442',
                                    "type": 'north'
                                  }
                                ],
                                "type": 'bounding box coordinates',
                                "encoding": {
                                  "value": 'decimal'
                                },
                                "standard": {
                                  "code": 'EPSG:4326',
                                  "type": 'coordinate reference system'
                                }
                              }
                            ]
                          })
    end
  end

  # 6. Raster image converted from ISO 19139
  context 'with a raster image converteed from ISO 19139' do
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <rdf:Description rdf:about="http://purl.stanford.edu/zz581px0362">
              <dc:format>image/tiff; format=GeoTIFF</dc:format>
              <dc:type>Dataset#Raster</dc:type>
              <gml:boundedBy>
                <gml:Envelope gml:srsName="EPSG:4326">
                  <gml:lowerCorner>-179.999988 3.0903369</gml:lowerCorner>
                  <gml:upperCorner>179.9892282 86.2537688</gml:upperCorner>
                </gml:Envelope>
              </gml:boundedBy>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq({
                            "form": [
                              {
                                "value": 'image/tiff',
                                "type": 'media type',
                                "source": {
                                  "value": 'IANA media type terms'
                                }
                              },
                              {
                                "value": 'GeoTIFF',
                                "type": 'data format'
                              },
                              {
                                "value": 'Dataset#Raster',
                                "type": 'type'
                              }
                            ],
                            "subject": [
                              {
                                "structuredValue": [
                                  {
                                    "value": '-179.999988',
                                    "type": 'west'
                                  },
                                  {
                                    "value": '3.0903369',
                                    "type": 'south'
                                  },
                                  {
                                    "value": '179.9892282',
                                    "type": 'east'
                                  },
                                  {
                                    "value": '86.2537688',
                                    "type": 'north'
                                  }
                                ],
                                "type": 'bounding box coordinates',
                                "encoding": {
                                  "value": 'decimal'
                                },
                                "standard": {
                                  "code": 'EPSG:4326',
                                  "type": 'coordinate reference system'
                                }
                              }
                            ]
                          })
    end
  end

  # 7. Geonames and unauthorized subject terms
  context 'with geonames and unauthorized subject terms' do
    let(:xml) do
      <<~XML
        <extension displayLabel="geo">
          <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <rdf:Description rdf:about="http://purl.stanford.edu/zg154pd4168">
              <dc:format>application/x-esri-shapefile; format=Shapefile</dc:format>
              <dc:type>Dataset#Polygon</dc:type>
              <gml:boundedBy>
                <gml:Envelope gml:srsName="EPSG:4326">
                  <gml:lowerCorner>-123.794776 39.296726</gml:lowerCorner>
                  <gml:upperCorner>-123.458655 39.433878</gml:upperCorner>
                </gml:Envelope>
              </gml:boundedBy>
              <dc:coverage rdf:resource="" dc:language="eng" dc:title="California, Northern"/>
              <dc:coverage rdf:resource="" dc:language="eng" dc:title="Jackson Demonstration State Forest (Calif.)"/>
              <dc:coverage rdf:resource="http://sws.geonames.org/5372163/" dc:language="eng" dc:title="Mendocino County (Calif.)"/>
            </rdf:Description>
          </rdf:RDF>
        </extension>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq({
                            "form": [
                              {
                                "value": 'application/x-esri-shapefile',
                                "type": 'media type',
                                "source": {
                                  "value": 'IANA media type terms'
                                }
                              },
                              {
                                "value": 'Shapefile',
                                "type": 'data format'
                              },
                              {
                                "value": 'Dataset#Polygon',
                                "type": 'type'
                              }
                            ],
                            "subject": [
                              {
                                "structuredValue": [
                                  {
                                    "value": '-123.794776',
                                    "type": 'west'
                                  },
                                  {
                                    "value": '39.296726',
                                    "type": 'south'
                                  },
                                  {
                                    "value": '-123.458655',
                                    "type": 'east'
                                  },
                                  {
                                    "value": '39.433878',
                                    "type": 'north'
                                  }
                                ],
                                "type": 'bounding box coordinates',
                                "encoding": {
                                  "value": 'decimal'
                                },
                                "standard": {
                                  "code": 'EPSG:4326',
                                  "type": 'coordinate reference system'
                                }
                              },
                              {
                                "value": 'California, Northern',
                                "type": 'coverage',
                                "language": {
                                  "code": 'eng'
                                }
                              },
                              {
                                "value": 'Jackson Demonstration State Forest (Calif.)',
                                "type": 'coverage',
                                "language": {
                                  "code": 'eng'
                                }
                              },
                              {
                                "value": 'Mendocino County (Calif.)',
                                "type": 'coverage',
                                "language": {
                                  "code": 'eng'
                                },
                                "uri": 'http://sws.geonames.org/5372163/'
                              }
                            ]
                          })
    end
  end
end

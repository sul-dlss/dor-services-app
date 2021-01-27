# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Form do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { instance_double(Cocina::FromFedora::Descriptive::DescriptiveBuilder, notifier: notifier) }

  let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  describe 'genre' do
    context 'with authority missing valueURI' do
      let(:xml) do
        <<~XML
          <genre authority="lcgft" authorityURI="http://id.loc.gov/authorities/genreForms/">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre',
            "source": {
              "code": 'lcgft',
              "uri": 'http://id.loc.gov/authorities/genreForms/'
            }
          }
        ]
      end
    end

    context 'with authority missing authorityURI' do
      let(:xml) do
        <<~XML
          <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2017027249">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre',
            "uri": 'http://id.loc.gov/authorities/genreForms/gf2017027249',
            "source": {
              "code": 'lcgft'
            }
          }
        ]
      end
    end

    context 'with empty authority' do
      let(:xml) do
        <<~XML
          <genre authority="">Photographs</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'Photographs',
            "type": 'genre'
          }
        ]
      end
    end
  end

  describe 'subject' do
    context 'when there is a subject/cartographics node with empty elements' do
      let(:xml) do
        <<~XML
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale />
              <projection />
            </cartographics>
          </subject>
        XML
      end

      it 'ignores empty elements' do
        expect(build).to eq []
      end
    end

    context 'when there is a subject/genre node' do
      let(:xml) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85120809">
            <name type="personal">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
            <titleInfo>
              <title>Hamlet</title>
            </titleInfo>
            <genre>Bibliographies</genre>
          </subject>
        XML
      end

      it 'ignores the genre node' do
        expect(build).to eq []
      end
    end
  end

  # From https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/h2_cocina_mappings/h2_to_cocina_form.txt
  describe 'H2 work types & subtypes' do
    context 'with text / article' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Text</genre>
          <genre type="H2 subtype">Article</genre>
          <genre valueURI="http://vocab.getty.edu/aat/300048715" authority="aat">articles</genre>
          <typeOfResource>text</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Text',
                type: 'type'
              },
              {
                value: 'Article',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'articles',
            type: 'genre',
            uri: 'http://vocab.getty.edu/aat/300048715',
            source: {
              code: 'aat'
            }
          },
          {
            value: 'text',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with text / essay' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Text</genre>
          <genre type="H2 subtype">Essay</genre>
          <genre valueURI="http://id.loc.gov/authorities/genreForms/gf2014026094" authority="lcgft">Essays</genre>
          <typeOfResource>text</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Text',
                type: 'type'
              },
              {
                value: 'Essay',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'Essays',
            type: 'genre',
            uri: 'http://id.loc.gov/authorities/genreForms/gf2014026094',
            source: {
              code: 'lcgft'
            }
          },
          {
            value: 'text',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with data / 3d model' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Data</genre>
          <genre type="H2 subtype">3D model</genre>
          <genre>Three dimensional scan</genre>
          <typeOfResource>three dimensional object</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Data',
                type: 'type'
              },
              {
                value: '3D model',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'Three dimensional scan',
            type: 'genre'
          },
          {
            value: 'three dimensional object',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with data / GIS' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Data</genre>
          <genre type="H2 subtype">GIS</genre>
          <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2011026294">Geographic information systems</genre>
          <genre>dataset</genre>
          <typeOfResource>cartographic</typeOfResource>
          <typeOfResource>software, multimedia</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Data',
                type: 'type'
              },
              {
                value: 'GIS',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'Geographic information systems',
            type: 'genre',
            uri: 'http://id.loc.gov/authorities/genreForms/gf2011026294',
            source: {
              code: 'lcgft'
            }
          },
          {
            value: 'dataset',
            type: 'genre'
          },
          {
            value: 'cartographic',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          },
          {
            value: 'software, multimedia',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with software / code, documentation' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Software</genre>
          <genre type="H2 subtype">Code</genre>
          <genre type="H2 subtype">Documentation</genre>
          <genre authority="aat" valueURI="http://vocab.getty.edu/aat/300312188">programs (computer)</genre>
          <genre authority="aat" valueURI="http://vocab.getty.edu/aat/300026413">technical manuals</genre>
          <typeOfResource>software, multimedia</typeOfResource>
          <typeOfResource>text</typeOfResource>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Software',
                type: 'type'
              },
              {
                value: 'Code',
                type: 'subtype'
              },
              {
                value: 'Documentation',
                type: 'subtype'
              }

            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          },
          {
            value: 'programs (computer)',
            type: 'genre',
            uri: 'http://vocab.getty.edu/aat/300312188',
            source: {
              code: 'aat'
            }
          },
          {
            value: 'technical manuals',
            type: 'genre',
            uri: 'http://vocab.getty.edu/aat/300026413',
            source: {
              code: 'aat'
            }
          },
          {
            value: 'software, multimedia',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          },
          {
            value: 'text',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          }
        ]
      end
    end

    context 'with other / dance notation' do
      let(:xml) do
        <<~XML
          <genre type="H2 type">Other</genre>
          <genre type="H2 subtype">Dance notation</genre>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            structuredValue: [
              {
                value: 'Other',
                type: 'type'
              },
              {
                value: 'Dance notation',
                type: 'subtype'
              }
            ],
            source: {
              value: 'Stanford self-deposit resource types'
            },
            type: 'resource type'
          }
        ]
      end
    end
  end

  describe 'physicalDescription' do
    context 'when note does not have displayLabel' do
      let(:xml) do
        <<~XML
          <physicalDescription>
            <form>ink on paper</form>
            <note>Small tear at top right corner.</note>
          </physicalDescription>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'ink on paper',
            "type": 'form'
          },
          {
            "note": [
              {
                "value": 'Small tear at top right corner.'
              }
            ]
          }
        ]
      end
    end

    context 'when physical description elsewhere in record' do
      let(:xml) do
        <<~XML
          <relatedItem type="original">
              <physicalDescription>
                 <form authority="marcform">print</form>
                 <extent>v. ; 24 cm.</extent>
              </physicalDescription>
           </relatedItem>
          <physicalDescription>
            <form>mezzotints (prints)</form>
          </physicalDescription>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "value": 'mezzotints (prints)',
            "type": 'form'
          }
        ]
      end
    end
  end
end

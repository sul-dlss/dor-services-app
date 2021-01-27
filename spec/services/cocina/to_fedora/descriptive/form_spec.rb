# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Form do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, forms: forms)
      end
    end
  end

  context 'when form is nil' do
    let(:forms) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  # From https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/h2_cocina_mappings/h2_to_cocina_form.txt
  describe 'H2 work types & subtypes' do
    context 'with text / article' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
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
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'articles',
            type: 'genre',
            uri: 'http://vocab.getty.edu/aat/300048715',
            source: {
              code: 'aat'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'text',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
          <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre type="H2 type">Text</genre>
            <genre type="H2 subtype">Article</genre>
            <genre valueURI="http://vocab.getty.edu/aat/300048715" authority="aat">articles</genre>
            <typeOfResource>text</typeOfResource>
          </mods>
        XML
      end
    end

    context 'with text / essay' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
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
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'Essays',
            type: 'genre',
            uri: 'http://id.loc.gov/authorities/genreForms/gf2014026094',
            source: {
              code: 'lcgft'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'text',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
          <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre type="H2 type">Text</genre>
            <genre type="H2 subtype">Essay</genre>
            <genre valueURI="http://id.loc.gov/authorities/genreForms/gf2014026094" authority="lcgft">Essays</genre>
            <typeOfResource>text</typeOfResource>
          </mods>
        XML
      end
    end

    context 'with data / 3d model' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
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
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'Three dimensional scan',
            type: 'genre'
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'three dimensional object',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
          <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre type="H2 type">Data</genre>
            <genre type="H2 subtype">3D model</genre>
            <genre>Three dimensional scan</genre>
            <typeOfResource>three dimensional object</typeOfResource>
          </mods>
        XML
      end
    end

    context 'with data / GIS' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
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
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'Geographic information systems',
            type: 'genre',
            uri: 'http://id.loc.gov/authorities/genreForms/gf2011026294',
            source: {
              code: 'lcgft'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'dataset',
            type: 'genre'
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'cartographic',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'software, multimedia',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
          <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre type="H2 type">Data</genre>
            <genre type="H2 subtype">GIS</genre>
            <genre authority="lcgft" valueURI="http://id.loc.gov/authorities/genreForms/gf2011026294">Geographic information systems</genre>
            <genre>dataset</genre>
            <typeOfResource>cartographic</typeOfResource>
            <typeOfResource>software, multimedia</typeOfResource>
          </mods>
        XML
      end
    end

    context 'with software / code, documentation' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
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
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'programs (computer)',
            type: 'genre',
            uri: 'http://vocab.getty.edu/aat/300312188',
            source: {
              code: 'aat'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'technical manuals',
            type: 'genre',
            uri: 'http://vocab.getty.edu/aat/300026413',
            source: {
              code: 'aat'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'software, multimedia',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          ),
          Cocina::Models::DescriptiveValue.new(
            value: 'text',
            type: 'resource type',
            source: {
              value: 'MODS resource types'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
          <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre type="H2 type">Software</genre>
            <genre type="H2 subtype">Code</genre>
            <genre type="H2 subtype">Documentation</genre>
            <genre authority="aat" valueURI="http://vocab.getty.edu/aat/300312188">programs (computer)</genre>
            <genre authority="aat" valueURI="http://vocab.getty.edu/aat/300026413">technical manuals</genre>
            <typeOfResource>software, multimedia</typeOfResource>
            <typeOfResource>text</typeOfResource>
          </mods>
        XML
      end
    end

    context 'with other / dance notation' do
      let(:forms) do
        [
          Cocina::Models::DescriptiveValue.new(
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
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
          <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <genre type="H2 type">Other</genre>
            <genre type="H2 subtype">Dance notation</genre>
          </mods>
        XML
      end
    end
  end
end

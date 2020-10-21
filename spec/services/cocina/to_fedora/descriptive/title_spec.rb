# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Title do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, titles: titles)
      end
    end
  end

  describe 'title' do
    context 'when it is a basic value' do
      let(:titles) do
        [
          Cocina::Models::DescriptiveValueRequired.new(
            { value: 'Gaudy night' }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title>Gaudy night</title>
            </titleInfo>
          </mods>
        XML
      end
    end

    context 'when it has a structured value' do
      let(:titles) do
        [
          Cocina::Models::DescriptiveValueRequired.new(
            { structuredValue: [{ type: 'nonsorting characters', value: 'The' },
                                { type: 'main title', value: 'journal of stuff' },
                                { type: 'subtitle', value: 'a journal' },
                                { type: 'part number', value: 'volume 5' },
                                { type: 'part name', value: 'special issue' },
                                { note: [{ type: 'nonsorting character count', value: '4' }] }] }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <nonSort>The</nonSort>
              <title>journal of stuff</title>
              <subTitle>a journal</subTitle>
              <partNumber>volume 5</partNumber>
              <partName>special issue</partName>
            </titleInfo>
          </mods>
        XML
      end
    end

    context 'when it has an alternative' do
      let(:titles) do
        [
          Cocina::Models::DescriptiveValueRequired.new(
            {
              value: 'Five red herrings',
              status: 'primary'
            }
          ),
          Cocina::Models::DescriptiveValueRequired.new(
            {
              value: 'Suspicious characters',
              type: 'alternative'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary">
              <title>Five red herrings</title>
            </titleInfo>
            <titleInfo type="alternative">
              <title>Suspicious characters</title>
            </titleInfo>
          </mods>
        XML
      end
    end

    context 'when it is translated' do
      let(:titles) do
        [
          Cocina::Models::DescriptiveValueRequired.new(
            {
              parallelValue: [
                Cocina::Models::DescriptiveValueRequired.new(
                  {
                    structuredValue: [
                      {
                        value: 'Les',
                        type: 'nonsorting characters'
                      },
                      {
                        value: 'misérables',
                        type: 'main title'
                      },
                      {
                        note: [
                          {
                            value: '4',
                            type: 'nonsorting character count'
                          }
                        ]
                      }
                    ],
                    status: 'primary',
                    valueLanguage: {
                      code: 'fre',
                      source: {
                        code: 'iso639-2b'
                      }
                    }
                  }
                ),
                Cocina::Models::DescriptiveValueRequired.new(
                  {
                    structuredValue: [
                      {
                        value: 'The',
                        type: 'nonsorting characters'
                      },
                      {
                        value: 'wretched',
                        type: 'main title'
                      },
                      {
                        note: [
                          {
                            value: '4',
                            type: 'nonsorting character count'
                          }
                        ]
                      }
                    ],
                    type: 'translated',
                    valueLanguage: {
                      code: 'eng',
                      source: {
                        code: 'iso639-2b'
                      }
                    }
                  }
                )
              ]
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary" lang="fre" altRepGroup="0">
              <nonSort>Les</nonSort>
              <title>mis&#xE9;rables</title>
            </titleInfo>
            <titleInfo type="translated" lang="eng" altRepGroup="0">
              <nonSort>The</nonSort>
              <title>wretched</title>
            </titleInfo>
          </mods>
        XML
      end
    end

    context 'when it is transliterated (title is value)' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L157'
    end

    context 'when it is a uniform title with authority' do
      let(:titles) do
        [
          Cocina::Models::DescriptiveValueRequired.new(
            "value": 'Hamlet',
            "status": 'primary'
          ),
          Cocina::Models::DescriptiveValueRequired.new(
            "structuredValue": [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'person',
                "uri": 'http://id.loc.gov/authorities/names/n78095332',
                "source": {
                  "uri": 'http://id.loc.gov/authorities/names/',
                  "code": 'naf'
                }
              },
              {
                "value": 'Hamlet',
                "type": 'main title'
              }
            ],
            "type": 'uniform',
            "uri": 'http://id.loc.gov/authorities/names/n80008522',
            "source": {
              "uri": 'http://id.loc.gov/authorities/names/',
              "code": 'naf'
            }
          )
        ]
      end

      it 'creates the equivalent MODS' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary">
              <title>Hamlet</title>
            </titleInfo>
            <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80008522" nameTitleGroup="1">
              <title>Hamlet</title>
            </titleInfo>
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="1">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
          </mods>
        XML
      end
    end

    context 'when it is a uniform title with multiple namePart subelements' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L243'
    end

    context 'when it is supplied' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L278'
    end

    context 'when it is abbreviated' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L292'
    end

    context 'when it is parallel title' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L316'
    end

    context 'when it is multiple untyped titles without primary' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L365'
    end

    context 'when it is multiple typed titles without primary' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L383'
    end

    context 'when it has a display label' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L402'
    end
  end
end

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
          Cocina::Models::Title.new(
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
          Cocina::Models::Title.new(
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

    context 'when it is a uniform title with multiple namePart subelements' do
      # xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L243'
      let(:titles) do
        [
          Cocina::Models::Title.new(
            { structuredValue: [{ type: 'surname', value: 'Saint-Saëns' },
                                { type: 'forename', value: 'Camille' },
                                { type: 'life dates', value: '1835-1921' },
                                { type: 'title', value: 'Princesse jaune. Vocal score' },
                                { type: 'term of address', value: 'Princess' }],
              type: 'uniform',
              status: 'primary' }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo type="uniform" usage="primary" nameTitleGroup="1">
              <title>Princesse jaune. Vocal score</title>
            </titleInfo>
            <name type="personal" usage="primary" nameTitleGroup="1">
              <namePart type="family">Saint-Sa&#xEB;ns</namePart>
              <namePart type="given">Camille</namePart>
              <namePart type="date">1835-1921</namePart>
              <namePart type="termsOfAddress">Princess</namePart>
            </name>
          </mods>
        XML
      end
    end

    context 'when it is a multilingual uniform title' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            "structuredValue": [
              {
                "value": 'Mishnah berurah',
                "type": 'main title'
              },
              {
                "value": 'the classic commentary to Shulchan aruch Orach chayim, comprising the laws of daily Jewish conduct',
                "type": 'subtitle'
              }
            ]
          ),
          Cocina::Models::Title.new(
            "parallelValue": [
              {
                "structuredValue": [
                  {
                    "value": 'Israel Meir',
                    "type": 'name'
                  },
                  {
                    "value": 'ha-Kohen',
                    "type": 'term of address'
                  },
                  {
                    "value": '1838-1933',
                    "type": 'life dates'
                  },
                  {
                    "value": 'Mishnah berurah. English and Hebrew',
                    "type": 'title'
                  }
                ]
              },
              {
                "structuredValue": [
                  {
                    "value": 'Israel Meir in Hebrew characters',
                    "type": 'name'
                  },
                  {
                    "value": '1838-1933',
                    "type": 'life dates'
                  },
                  {
                    "value": 'Mishnah berurah in Hebrew characters',
                    "type": 'title'
                  }
                ]
              }
            ],
            "type": 'uniform'
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title>Mishnah berurah</title>
              <subTitle>the classic commentary to Shulchan aruch Orach chayim, comprising the laws of daily Jewish conduct</subTitle>
            </titleInfo>
            <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="1">
              <title>Mishnah berurah. English and Hebrew</title>
            </titleInfo>
            <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
              <namePart>Israel Meir</namePart>
              <namePart type="termsOfAddress">ha-Kohen</namePart>
              <namePart type="date">1838-1933</namePart>
            </name>
            <titleInfo type="uniform" nameTitleGroup="2" altRepGroup="1">
              <title>Mishnah berurah in Hebrew characters</title>
            </titleInfo>
            <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="2">
              <namePart>Israel Meir in Hebrew characters</namePart>
              <namePart type="date">1838-1933</namePart>
            </name>
        XML
      end
    end

    context 'when it has an alternative' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            {
              value: 'Five red herrings',
              status: 'primary'
            }
          ),
          Cocina::Models::Title.new(
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
          Cocina::Models::Title.new(
            {
              parallelValue: [
                Cocina::Models::Title.new(
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
                Cocina::Models::Title.new(
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
            <titleInfo usage="primary" lang="fre" altRepGroup="1">
              <nonSort>Les</nonSort>
              <title>mis&#xE9;rables</title>
            </titleInfo>
            <titleInfo type="translated" lang="eng" altRepGroup="1">
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
          Cocina::Models::Title.new(
            "value": 'Hamlet',
            "status": 'primary'
          ),
          Cocina::Models::Title.new(
            "structuredValue": [
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'name',
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
            <titleInfo type="uniform" nameTitleGroup="1" valueURI="http://id.loc.gov/authorities/names/n80008522" authorityURI="http://id.loc.gov/authorities/names/" authority="naf">
              <title>Hamlet</title>
            </titleInfo>
            <name type="personal" nameTitleGroup="1" valueURI="http://id.loc.gov/authorities/names/n78095332" authorityURI="http://id.loc.gov/authorities/names/" authority="naf">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
          </mods>
        XML
      end
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

    context 'when it is a parallel title without type' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            "parallelValue": [
              {
                "value": 'Zi yuan wei yuan hui yue kan'
              },
              {
                "value": '資源委員會月刊'
              }
            ],
            "type": 'parallel'
          )
        ]
      end

      it 'creates the equivalent MODS' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
               <titleInfo altRepGroup="1">
                  <title>Zi yuan wei yuan hui yue kan</title>
               </titleInfo>
               <titleInfo altRepGroup="1">
                  <title>&#x8CC7;&#x6E90;&#x59D4;&#x54E1;&#x6703;&#x6708;&#x520A;</title>
               </titleInfo>
          </mods>
        XML
      end
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

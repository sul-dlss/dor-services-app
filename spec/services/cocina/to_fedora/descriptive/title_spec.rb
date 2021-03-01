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
        described_class.write(xml: xml, titles: titles, contributors: contributors, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  let(:contributors) { [] }

  describe 'title' do
    context 'when there is a title with language' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            value: 'Union des Forces de Changement du Togo',
            valueLanguage: {
              code: 'fre',
              source: {
                code: 'iso639-2b'
              },
              valueScript: {
                code: 'Latn',
                source: {
                  code: 'iso15924'
                }
              }
            }
          )
        ]
      end

      it 'creates the equivalent MODS' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo lang="fre" script="Latn">
              <title>Union des Forces de Changement du Togo</title>
              </titleInfo>
          </mods>
        XML
      end
    end

    context 'when it is a uniform title with multiple title subelements' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            {
              structuredValue: [
                {
                  type: 'title',
                  structuredValue: [
                    {
                      value: 'Concertos, recorder, string orchestra',
                      type: 'main title'
                    },
                    {
                      value: 'RV 441, C minor',
                      type: 'part number'
                    }
                  ]
                },
                {
                  structuredValue: [
                    {
                      value: 'Vivaldi, Antonio',
                      type: 'name'
                    },
                    {
                      value: '1678-1741',
                      type: 'life dates'
                    }
                  ],
                  type: 'name'
                }
              ],
              type: 'uniform'
            }
          )
        ]
      end

      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            {
              name: [
                {
                  structuredValue: [
                    {
                      value: 'Vivaldi, Antonio',
                      type: 'name'
                    },
                    {
                      value: '1678-1741',
                      type: 'life dates'
                    }
                  ]
                }
              ],
              type: 'person',
              status: 'primary'
            }
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo type="uniform" nameTitleGroup="1">
              <title>Concertos, recorder, string orchestra</title>
              <partNumber>RV 441, C minor</partNumber>
            </titleInfo>
            <name type="personal" usage="primary" nameTitleGroup="1">
              <namePart>Vivaldi, Antonio</namePart>
              <namePart type="date">1678-1741</namePart>
            </name>
          </mods>
        XML
      end
    end

    context 'when there is a title with script but no lang' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            value: 'Война и миръ',
            valueLanguage: {
              valueScript: {
                code: 'Cyrl',
                source: {
                  code: 'iso15924'
                }
              }
            }
          )
        ]
      end

      it 'creates the equivalent MODS' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo script="Cyrl">
              <title>&#x412;&#x43E;&#x439;&#x43D;&#x430; &#x438; &#x43C;&#x438;&#x440;&#x44A;</title>
            </titleInfo>
          </mods>
        XML
      end
    end

    context 'when it is a parallel title without type' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            parallelValue: [
              {
                value: 'Zi yuan wei yuan hui yue kan'
              },
              {
                value: '資源委員會月刊'
              }
            ],
            type: 'parallel'
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

    context 'when it is a parallel title with script but no lang' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            parallelValue: [
              {
                value: '[Chosen] Gomanbunnnoichi Chikeizu',
                valueLanguage: {
                  valueScript: {
                    code: 'Latn',
                    source: {
                      code: 'iso15924'
                    }
                  }
                }
              },
              {
                value: '[朝鮮] 五万分一地形圖',
                valueLanguage: {
                  valueScript: {
                    code: 'Latn',
                    source: {
                      code: 'iso15924'
                    }
                  }
                }
              }
            ],
            type: 'parallel'
          )
        ]
      end

      it 'creates the equivalent MODS' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo script="Latn" altRepGroup="1">
              <title>[Chosen] Gomanbunnnoichi Chikeizu</title>
            </titleInfo>
            <titleInfo script="Latn" altRepGroup="1">
              <title>[&#x671D;&#x9BAE;] &#x4E94;&#x4E07;&#x5206;&#x4E00;&#x5730;&#x5F62;&#x5716;</title>
            </titleInfo>
          </mods>
        XML
      end
    end

    context 'when it is a title and contributor have same value' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            {
              value: 'Stanford Alpine Club'
            }
          )
        ]
      end

      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            {
              name: [
                {
                  value: 'Stanford Alpine Club',
                  uri: 'http://id.loc.gov/authorities/names/n99277320',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              type: 'organization',
              status: 'primary'
            }
          )
        ]
      end

      # Note that not made into nameTitleGroup
      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title>Stanford Alpine Club</title>
            </titleInfo>
          </mods>
        XML
      end
    end
  end

  # Example 21
  context 'when it is a complex multilingual title' do
    let(:titles) do
      [
        Cocina::Models::Title.new(
          structuredValue: [
            {
              structuredValue: [
                {
                  value: 'Vital, Ḥayyim ben Joseph',
                  type: 'name'
                },
                {
                  value: '1542 or 1543-1620',
                  type: 'life dates'
                }
              ],
              type: 'name'
            },
            {
              value: 'Shaʻare ha-ḳedushah',
              type: 'title'
            }
          ],
          type: 'uniform'
        ),
        Cocina::Models::Title.new(
          parallelValue: [
            {
              structuredValue: [
                {
                  value: 'Sefer Shaʻare ha-ḳedushah in Hebrew',
                  type: 'main title'
                },
                {
                  value: 'zeh sefer le-yosher ha-adam la-ʻavodat borʼo in Hebrew',
                  type: 'subtitle'
                }
              ]
            },
            {
              structuredValue: [
                {
                  value: 'Sefer Shaʻare ha-ḳedushah',
                  type: 'main title'
                },
                {
                  value: 'zeh sefer le-yosher ha-adam la-ʻavodat borʼo',
                  type: 'subtitle'
                }
              ]
            }
          ]
        )
      ]
    end

    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              structuredValue: [
                {
                  value: 'Vital, Ḥayyim ben Joseph',
                  type: 'name'
                },
                {
                  value: '1542 or 1543-1620',
                  type: 'life dates'
                }
              ]
            }
          ],
          type: 'person',
          status: 'primary'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo type="uniform" nameTitleGroup="1">
            <title>Shaʻare ha-ḳedushah</title>
          </titleInfo>
          <titleInfo altRepGroup="1">
            <title>Sefer Shaʻare ha-ḳedushah in Hebrew</title>
            <subTitle>zeh sefer le-yosher ha-adam la-ʻavodat borʼo in Hebrew</subTitle>
          </titleInfo>
          <titleInfo altRepGroup="1">
            <title>Sefer Shaʻare ha-ḳedushah</title>
            <subTitle>zeh sefer le-yosher ha-adam la-ʻavodat borʼo</subTitle>
          </titleInfo>
          <name type="personal" usage="primary" nameTitleGroup="1">
            <namePart>Vital, Ḥayyim ben Joseph</namePart>
            <namePart type="date">1542 or 1543-1620</namePart>
          </name>
        </mods>
      XML
    end
  end
end

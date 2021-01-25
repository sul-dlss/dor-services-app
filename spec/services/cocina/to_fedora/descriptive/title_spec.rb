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

    context 'when there is a title with language' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            "value": 'Union des Forces de Changement du Togo',
            "valueLanguage": {
              "code": 'fre',
              "source": {
                "code": 'iso639-2b'
              },
              "valueScript": {
                "code": 'Latn',
                "source": {
                  "code": 'iso15924'
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

    context 'when it has a structured value' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            {
              structuredValue: [
                { type: 'nonsorting characters', value: 'The' },
                { type: 'main title', value: 'journal of stuff' },
                { type: 'subtitle', value: 'a journal' },
                { type: 'part number', value: 'volume 5' },
                { type: 'part name', value: 'special issue' }
              ],
              note: [
                { type: 'nonsorting character count', value: '4' }
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
      let(:titles) do
        [
          Cocina::Models::Title.new(
            {
              "structuredValue": [
                {
                  "structuredValue": [
                    {
                      "value": 'Saint-Saëns',
                      "type": 'surname'
                    },
                    {
                      "value": 'Camille',
                      "type": 'forename'
                    },
                    {
                      "value": '1835-1921',
                      "type": 'life dates'
                    }
                  ],
                  "type": 'name'
                },
                {
                  "value": 'Princesse jaune. Vocal score',
                  "type": 'title'
                }
              ],
              "type": 'uniform'
            }
          )
        ]
      end

      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            {
              "name": [
                {
                  "structuredValue": [
                    {
                      "value": 'Saint-Saëns',
                      "type": 'surname'
                    },
                    {
                      "value": 'Camille',
                      "type": 'forename'
                    },
                    {
                      "value": '1835-1921',
                      "type": 'life dates'
                    }
                  ]
                }
              ],
              "type": 'person',
              "status": 'primary'
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
              <title>Princesse jaune. Vocal score</title>
            </titleInfo>
            <name type="personal" usage="primary" nameTitleGroup="1">
              <namePart type="family">Saint-Sa&#xEB;ns</namePart>
              <namePart type="given">Camille</namePart>
              <namePart type="date">1835-1921</namePart>
            </name>
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
              "name": [
                {
                  "structuredValue": [
                    {
                      "value": 'Vivaldi, Antonio',
                      "type": 'name'
                    },
                    {
                      "value": '1678-1741',
                      "type": 'life dates'
                    }
                  ]
                }
              ],
              "type": 'person',
              "status": 'primary'
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

    # Example 18
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
                      }
                    ],
                    "type": 'name'
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
                    "structuredValue": [
                      {
                        "value": 'Israel Meir in Hebrew characters',
                        "type": 'name'
                      },
                      {
                        "value": '1838-1933',
                        "type": 'life dates'
                      }
                    ],
                    "type": 'name'
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

      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            {
              "type": 'person',
              "name": [
                {
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
                        }
                      ],
                      "status": 'primary'
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
                        }
                      ],
                      "status": 'primary'
                    }
                  ]
                }
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
            <titleInfo>
              <title>Mishnah berurah</title>
              <subTitle>the classic commentary to Shulchan aruch Orach chayim, comprising the laws of daily Jewish conduct</subTitle>
            </titleInfo>
            <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="1">
              <title>Mishnah berurah. English and Hebrew</title>
            </titleInfo>
            <titleInfo type="uniform" nameTitleGroup="2" altRepGroup="1">
              <title>Mishnah berurah in Hebrew characters</title>
            </titleInfo>
            <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
              <namePart>Israel Meir</namePart>
              <namePart type="termsOfAddress">ha-Kohen</namePart>
              <namePart type="date">1838-1933</namePart>
            </name>
            <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="2">
              <namePart>Israel Meir in Hebrew characters</namePart>
              <namePart type="date">1838-1933</namePart>
            </name>
          </mods>
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
                      }
                    ],
                    note: [
                      {
                        value: '4',
                        type: 'nonsorting character count'
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
                      }
                    ],
                    note: [
                      {
                        value: '4',
                        type: 'nonsorting character count'
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
      # https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L157'
      let(:titles) do
        [
          Cocina::Models::Title.new(
            "parallelValue": [
              {
                "value": 'Война и миръ',
                "status": 'primary',
                "valueLanguage": {
                  "code": 'rus',
                  "source": {
                    "code": 'iso639-2b'
                  },
                  "valueScript": {
                    "code": 'Cyrl',
                    "source": {
                      "code": 'iso15924'
                    }
                  }
                }
              },
              {
                "value": 'Voĭna i mir',
                "valueLanguage": {
                  "code": 'rus',
                  "source": {
                    "code": 'iso639-2b'
                  },
                  "valueScript": {
                    "code": 'Latn',
                    "source": {
                      "code": 'iso15924'
                    }
                  }
                },
                "type": 'transliterated',
                "standard": {
                  "value": 'ALA-LC Romanization Tables'
                }
              }
            ]
          )
        ]
      end

      it 'creates the equivalent MODS' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary" lang="rus" script="Cyrl" altRepGroup="1">
              <title>Война и миръ</title>
            </titleInfo>
            <titleInfo type="translated" lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
              <title>Voĭna i mir</title>
            </titleInfo>
          </mods>
        XML
      end
    end

    context 'when there is a title with script but no lang' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            "value": 'Война и миръ',
            "valueLanguage": {
              "valueScript": {
                "code": 'Cyrl',
                "source": {
                  "code": 'iso15924'
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
                "type": 'title'
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

      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            {
              "name": [
                {
                  "value": 'Shakespeare, William, 1564-1616',
                  "type": 'person',
                  "status": 'primary',
                  "uri": 'http://id.loc.gov/authorities/names/n78095332',
                  "source": {
                    "uri": 'http://id.loc.gov/authorities/names/',
                    "code": 'naf'
                  }
                }
              ],
              "status": 'primary'
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
            <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="1">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
          </mods>
        XML
      end
    end

    context 'when it is supplied' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L278'
    end

    # Example 8
    context 'when it is abbreviated' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            "value": 'Annual report of notifiable diseases',
            "status": 'primary'
          ),
          Cocina::Models::Title.new(
            "value": 'Annu. rep. notif. dis.',
            "type": 'abbreviated',
            "source": {
              "code": 'dnlm'
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
                  <title>Annual report of notifiable diseases</title>
                </titleInfo>
                <titleInfo type="abbreviated" authority="dnlm">
                  <title>Annu. rep. notif. dis.</title>
                </titleInfo>
          </mods>
        XML
      end
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

    context 'when it is a parallel title with script but no lang' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            "parallelValue": [
              {
                "value": '[Chosen] Gomanbunnnoichi Chikeizu',
                "valueLanguage": {
                  "valueScript": {
                    "code": 'Latn',
                    "source": {
                      "code": 'iso15924'
                    }
                  }
                }
              },
              {
                "value": '[朝鮮] 五万分一地形圖',
                "valueLanguage": {
                  "valueScript": {
                    "code": 'Latn',
                    "source": {
                      "code": 'iso15924'
                    }
                  }
                }
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

    context 'when it is multiple untyped titles without primary' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L365'
    end

    context 'when it is multiple typed titles without primary' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L383'
    end

    context 'when it has a display label' do
      let(:titles) do
        [
          Cocina::Models::Title.new(
            {
              "value": 'Unnatural death',
              "status": 'primary'
            }
          ),
          Cocina::Models::Title.new(
            {
              "value": 'The Dawson pedigree',
              "type": 'alternative',
              "displayLabel": 'Original U.S. title'
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
              <title>Unnatural death</title>
            </titleInfo>
            <titleInfo type="alternative" displayLabel="Original U.S. title">
              <title>The Dawson pedigree</title>
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
              "value": 'Stanford Alpine Club'
            }
          )
        ]
      end

      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            {
              "name": [
                {
                  "value": 'Stanford Alpine Club',
                  "uri": 'http://id.loc.gov/authorities/names/n99277320',
                  "source": {
                    "code": 'naf',
                    "uri": 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              "type": 'organization',
              "status": 'primary'
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
          "structuredValue": [
            {
              "structuredValue": [
                {
                  "value": 'Vital, Ḥayyim ben Joseph',
                  "type": 'name'
                },
                {
                  "value": '1542 or 1543-1620',
                  "type": 'life dates'
                }
              ],
              "type": 'name'
            },
            {
              "value": 'Shaʻare ha-ḳedushah',
              "type": 'title'
            }
          ],
          "type": 'uniform'
        ),
        Cocina::Models::Title.new(
          "parallelValue": [
            {
              "structuredValue": [
                {
                  "value": 'Sefer Shaʻare ha-ḳedushah in Hebrew',
                  "type": 'main title'
                },
                {
                  "value": 'zeh sefer le-yosher ha-adam la-ʻavodat borʼo in Hebrew',
                  "type": 'subtitle'
                }
              ]
            },
            {
              "structuredValue": [
                {
                  "value": 'Sefer Shaʻare ha-ḳedushah',
                  "type": 'main title'
                },
                {
                  "value": 'zeh sefer le-yosher ha-adam la-ʻavodat borʼo',
                  "type": 'subtitle'
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
          "name": [
            {
              "structuredValue": [
                {
                  "value": 'Vital, Ḥayyim ben Joseph',
                  "type": 'name'
                },
                {
                  "value": '1542 or 1543-1620',
                  "type": 'life dates'
                }
              ]
            }
          ],
          "type": 'person',
          "status": 'primary'
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

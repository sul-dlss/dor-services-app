# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Titles do
  let(:object) { Dor::Item.new }

  describe '.build' do
    subject(:build) { described_class.build(resource_element: ng_xml.root, require_title: require_title) }

    let(:require_title) { true }

    context 'when the object has no title' do
      let(:ng_xml) { Dor::Item.new.descMetadata.ng_xml }

      it 'raises and error' do
        expect { build }.to raise_error Cocina::Mapper::MissingTitle
      end
    end

    context 'when the title is empty' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title />
            </titleInfo>
          </mods>
        XML
      end

      it 'raises and error' do
        expect { build }.to raise_error Cocina::Mapper::MissingTitle
      end
    end

    context 'when the object has no title and not required' do
      let(:ng_xml) { Dor::Item.new.descMetadata.ng_xml }

      let(:require_title) { false }

      it 'raises and error' do
        expect(build).to eq([])
      end
    end

    context 'when the title has parts' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <nonSort>The</nonSort>
              <title>journal of stuff</title>
              <partNumber>volume 5</partNumber>
              <partName>special issue</partName>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'is a structured value' do
        expect(build).to eq [
          {
            structuredValue: [
              { type: 'nonsorting characters', value: 'The' },
              { type: 'main title', value: 'journal of stuff' },
              { type: 'part number', value: 'volume 5' },
              { type: 'part name', value: 'special issue' }
            ],
            note: [
              { type: 'nonsorting character count', value: '4' }
            ]
          }
        ]
      end
    end

    context 'when there is an alternative title' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
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

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'has alternative type' do
        expect(build).to eq [
          { status: 'primary', value: 'Five red herrings' },
          { type: 'alternative', value: 'Suspicious characters' }
        ]
      end
    end

    context 'when there are empty titles' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary">
              <title>Five red herrings</title>
            </titleInfo>
            <titleInfo>
              <title />
            </titleInfo>
            <titleInfo type="alternative">
              <title />
            </titleInfo>
            <titleInfo type="alternative" displayLabel="Also known as: The Usual Suspects">
              <title />
            </titleInfo>
          </mods>
        XML
      end

      before do
        allow(Honeybadger).to receive(:notify)
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'ignores and notifies Honeybadger' do
        expect(build).to eq [
          { status: 'primary', value: 'Five red herrings' }
        ]
        expect(Honeybadger).to have_received(:notify).at_least(:once).with('[DATA ERROR] Empty title node', { tags: 'data_error' })
      end
    end

    context 'when there are title types' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title type="main">Monaco Grand Prix</title>
            </titleInfo>
          </mods>
        XML
      end

      before do
        allow(Honeybadger).to receive(:notify)
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'ignores and notifies Honeybadger' do
        expect(build).to eq [
          { value: 'Monaco Grand Prix' }
        ]
        expect(Honeybadger).to have_received(:notify).at_least(:once).with('[DATA ERROR] Title with type', { tags: 'data_error' })
      end
    end

    context 'when there is a translated title (title is structuredValue)' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary" lang="fre" altRepGroup="0">
              <nonSort>Les</nonSort>
              <title>misérables</title>
            </titleInfo>
            <titleInfo type="translated" lang="eng" altRepGroup="0">
              <nonSort>The</nonSort>
              <title>wretched</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates parallelValues' do
        expect(build).to eq [
          {
            "parallelValue": [
              {
                "structuredValue": [
                  {
                    "value": 'Les',
                    "type": 'nonsorting characters'
                  },
                  {
                    "value": 'misérables',
                    "type": 'main title'
                  }
                ],
                "note": [
                  {
                    "value": '4',
                    "type": 'nonsorting character count'
                  }
                ],
                "status": 'primary',
                "valueLanguage": {
                  "code": 'fre',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              },
              {
                "structuredValue": [
                  {
                    "value": 'The',
                    "type": 'nonsorting characters'
                  },
                  {
                    "value": 'wretched',
                    "type": 'main title'
                  }
                ],
                "note": [
                  {
                    "value": '4',
                    "type": 'nonsorting character count'
                  }
                ],
                "type": 'translated',
                "valueLanguage": {
                  "code": 'eng',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              }
            ]
          }
        ]
      end
    end

    context 'when there is a transliterated title (title is value)' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary" lang="rus" script="Cyrl" altRepGroup="0">
              <title>Война и миръ</title>
            </titleInfo>
            <titleInfo type="translated" lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="0">
              <title>Voĭna i mir</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates parallelValues' do
        expect(build).to eq [
          {
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
          }
        ]
      end
    end

    context 'when there is a title with script but no lang' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo script="Cyrl">
              <title>Война и миръ</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates model' do
        expect(build).to eq [
          {
            "value": 'Война и миръ',
            "valueLanguage": {
              "valueScript": {
                "code": 'Cyrl',
                "source": {
                  "code": 'iso15924'
                }
              }
            }
          }
        ]
      end
    end

    context 'when there is a title with empty script' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo script="">
              <title>Война и миръ</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates model' do
        expect(build).to eq [
          {
            "value": 'Война и миръ'
          }
        ]
      end
    end

    # Example 20 from mods_to_cocina_titleInfo.txt
    context 'when there are uniform titles with authority' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary">
              <title>Hamlet</title>
            </titleInfo>
            <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80008522" nameTitleGroup="0">
              <title>Hamlet</title>
            </titleInfo>
            <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="0">
              <namePart>Shakespeare, William, 1564-1616</namePart>
            </name>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates value from the authority record' do
        expect(build).to eq [
          {
            "value": 'Hamlet',
            "status": 'primary'
          },
          {
            "structuredValue": [
              {
                "value": 'Hamlet',
                "type": 'title'
              },
              {
                "value": 'Shakespeare, William, 1564-1616',
                "type": 'name',
                "uri": 'http://id.loc.gov/authorities/names/n78095332',
                "source": {
                  "uri": 'http://id.loc.gov/authorities/names/',
                  "code": 'naf'
                }
              }
            ],
            "type": 'uniform',
            "uri": 'http://id.loc.gov/authorities/names/n80008522',
            "source": {
              "uri": 'http://id.loc.gov/authorities/names/',
              "code": 'naf'
            }
          }
        ]
      end
    end

    # Example 21 from mods_to_cocina_titleInfo.txt
    context 'when there is a complex multilingual title' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="01">
              <title>Shaʻare ha-ḳedushah</title>
            </titleInfo>
            <name type="personal" usage="primary" nameTitleGroup="1">
              <namePart>Vital, Ḥayyim ben Joseph</namePart>
              <namePart type="date">1542 or 1543-1620</namePart>
            </name>
            <titleInfo altRepGroup="02">
              <title>Sefer Shaʻare ha-ḳedushah in Hebrew</title>
              <subTitle>zeh sefer le-yosher ha-adam la-ʻavodat borʼo in Hebrew</subTitle>
            </titleInfo>
            <titleInfo altRepGroup="02">
              <title>Sefer Shaʻare ha-ḳedushah</title>
              <subTitle>zeh sefer le-yosher ha-adam la-ʻavodat borʼo</subTitle>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates value from the authority record' do
        expect(build).to eq [
          {
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
          },
          {
            "structuredValue": [
              {
                type: 'title',
                value: 'Shaʻare ha-ḳedushah'
              },
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
              }
            ],
            "type": 'uniform'
          }
        ]
      end
    end

    context 'when there are uniform titles with multiple name part elements (all labeled)' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
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

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      xit 'creates value from the authority record' do
        expect(build).to eq [
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
        ]
      end
    end

    context 'when there are uniform titles with multiple name part elements (some unlabeled)' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo type="uniform" nameTitleGroup="1">
              <title>Tractatus de intellectus emendatione. German</title>
            </titleInfo>
            <name type="personal" usage="primary" nameTitleGroup="1">
              <namePart>Spinoza, Benedictus de</namePart>
              <namePart type="date">1632-1677</namePart>
            </name>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates value from the authority record' do
        expect(build).to eq [
          {
            "structuredValue": [
              {
                "value": 'Tractatus de intellectus emendatione. German',
                "type": 'title'
              },
              {
                "structuredValue": [
                  {
                    "value": 'Spinoza, Benedictus de',
                    "type": 'name'
                  },
                  {
                    "value": '1632-1677',
                    "type": 'life dates'
                  }
                ],
                "type": 'name'
              }
            ],
            "type": 'uniform'
          }
        ]
      end
    end

    context 'when there is a multilingual uniform title' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
              <titleInfo>
                <title>Mishnah berurah</title>
                <subTitle>the classic commentary to Shulchan aruch Orach chayim, comprising the laws of daily Jewish conduct</subTitle>
              </titleInfo>
              <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="01">
                <title>Mishnah berurah. English and Hebrew</title>
              </titleInfo>
              <name type="personal" usage="primary" altRepGroup="02" nameTitleGroup="1">
                <namePart>Israel Meir</namePart>
                <namePart type="termsOfAddress">ha-Kohen</namePart>
                <namePart type="date">1838-1933</namePart>
              </name>
              <name type="personal" usage="primary" altRepGroup="02" script="" nameTitleGroup="2">
                <namePart>Israel Meir in Hebrew characters</namePart>
                <namePart type="date">1838-1933</namePart>
              </name>
              <titleInfo type="uniform" nameTitleGroup="2" altRepGroup="01" script="">
                <title>Mishnah berurah in Hebrew characters</title>
              </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'builds cocina structure' do
        expect(build).to eq [
          {
            "parallelValue": [
              {
                "structuredValue": [
                  {
                    "value": 'Mishnah berurah. English and Hebrew',
                    "type": 'title'
                  },

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
                  }
                ]
              },
              {
                "structuredValue": [
                  {
                    "value": 'Mishnah berurah in Hebrew characters',
                    "type": 'title'
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
                    "type": 'name'
                  }
                ]
              }
            ],
            "type": 'uniform'
          },
          {
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
          }

        ]
      end
    end

    context 'when there is a missing nameTitleGroup' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80008522" nameTitleGroup="0">
              <title>Hamlet</title>
            </titleInfo>
          </mods>
        XML
      end

      before do
        allow(Honeybadger).to receive(:notify)
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates value from the authority record and Honeybadger notifies' do
        expect(build).to eq [
          {
            "structuredValue": [
              {
                "value": 'Hamlet',
                "type": 'title'
              }
            ],
            "type": 'uniform',
            "uri": 'http://id.loc.gov/authorities/names/n80008522',
            "source": {
              code: 'naf',
              uri: 'http://id.loc.gov/authorities/names/'
            }
          }
        ]
        expect(Honeybadger).to have_received(:notify).with('[DATA ERROR] Name not found for title group', { tags: 'data_error' })
      end
    end

    context 'when there are supplied titles' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo supplied="yes">
              <title>"Because I could not stop for death"</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates title with type=supplied' do
        expect(build).to eq [
          {
            "value": '"Because I could not stop for death"',
            "type": 'supplied'
          }
        ]
      end
    end

    context 'when there are abbreviated titles with authority' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
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

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates simple values' do
        expect(build).to eq [
          {
            "value": 'Annual report of notifiable diseases',
            "status": 'primary'
          },
          {
            "value": 'Annu. rep. notif. dis.',
            "type": 'abbreviated',
            "source": {
              "code": 'dnlm'
            }
          }
        ]
      end
    end

    context 'when there are abbreviated titles without authority' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary">
              <title>Annual report of notifiable diseases</title>
            </titleInfo>
            <titleInfo type="abbreviated">
              <title>Annu. rep. notif. dis.</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates simple values' do
        expect(build).to eq [
          {
            "value": 'Annual report of notifiable diseases',
            "status": 'primary'
          },
          {
            "value": 'Annu. rep. notif. dis.',
            "type": 'abbreviated'
          }
        ]
      end
    end

    context 'when there are parallel titles' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo type="translated" lang="ger" altRepGroup="0">
              <title>Berliner Mauer Kunst</title>
            </titleInfo>
            <titleInfo type="translated" lang="eng" altRepGroup="0">
              <title>Berlin's wall art</title>
            </titleInfo>
            <titleInfo type="translated" lang="spa" altRepGroup="0">
              <title>Arte en el muro de Berlin</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates parallelValues' do
        expect(build).to eq [
          {
            "parallelValue": [
              {
                "value": 'Berliner Mauer Kunst',
                "valueLanguage": {
                  "code": 'ger',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              },
              {
                "value": "Berlin's wall art",
                "valueLanguage": {
                  "code": 'eng',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              },
              {
                "value": 'Arte en el muro de Berlin',
                "valueLanguage": {
                  "code": 'spa',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              }
            ],
            "type": 'parallel'
          }
        ]
      end
    end

    context 'when there are multiple untyped titles without primary' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title>Symphony no. 6</title>
            </titleInfo>
            <titleInfo>
              <title>Pastoral symphony</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates simple values' do
        expect(build).to eq [
          {
            "value": 'Symphony no. 6'
          },
          {
            "value": 'Pastoral symphony'
          }
        ]
      end
    end

    context 'when there are multiple typed titles without primary' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title>Symphony no. 6</title>
            </titleInfo>
            <titleInfo type="alternative">
              <title>Pastoral symphony</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates simple values' do
        expect(build).to eq [
          {
            "value": 'Symphony no. 6'
          },
          {
            "value": 'Pastoral symphony',
            "type": 'alternative'
          }
        ]
      end
    end

    context 'when there is a title with a display label' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
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

      it 'parses' do
        expect { Cocina::Models::Description.new(title: build) }.not_to raise_error
      end

      it 'creates simple values' do
        expect(build).to eq [
          {
            "value": 'Unnatural death',
            "status": 'primary'
          },
          {
            "value": 'The Dawson pedigree',
            "type": 'alternative',
            "displayLabel": 'Original U.S. title'
          }
        ]
      end
    end
  end
end

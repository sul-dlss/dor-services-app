# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Titles do
  let(:object) { Dor::Item.new }

  describe '.build' do
    subject(:build) { described_class.build(ng_xml) }

    context 'when the object has no title' do
      let(:ng_xml) { Dor::Item.new.descMetadata.ng_xml }

      it 'raises and error' do
        expect { build }.to raise_error Cocina::Mapper::MissingTitle
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
          { structuredValue: [{ type: 'nonsorting characters', value: 'The' },
                              { type: 'main title', value: 'journal of stuff' },
                              { type: 'part number', value: 'volume 5' },
                              { type: 'part name', value: 'special issue' },
                              { note: [{ type: 'nonsorting character count', value: '4' }] }] }
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
                  },
                  {
                    "note": [
                      {
                        "value": '4',
                        "type": 'nonsorting character count'
                      }
                    ]
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
                  },
                  {
                    "note": [
                      {
                        "value": '4',
                        "type": 'nonsorting character count'
                      }
                    ]
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
            <name type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="0">
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
            "value": 'Shakespeare, William, 1564-1616. Hamlet',
            "type": 'uniform',
            "uri": 'http://id.loc.gov/authorities/names/n80008522'
          }
        ]
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

    context 'when there are abbreviated titles' do
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
            "type": 'parallel',
            "status": 'primary'
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

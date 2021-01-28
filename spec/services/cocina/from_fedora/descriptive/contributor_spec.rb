# frozen_string_literal: true

require 'rails_helper'

# numbered examples from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt
RSpec.describe Cocina::FromFedora::Descriptive::Contributor do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { Cocina::FromFedora::Descriptive::DescriptiveBuilder.new(notifier: notifier) }

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

  context 'with an invalid type' do
    context 'when miscapitalized' do
      let(:xml) do
        <<~XML
          <name type="Personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ],
            "type": 'person',
            "status": 'primary'
          }
        ]
        expect(notifier).to have_received(:warn).with('Name type incorrectly capitalized', { type: 'Personal' })
      end
    end

    context 'when unrecognized' do
      let(:xml) do
        <<~XML
          <name type="primary">
            <namePart>Vickery, Claire</namePart>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Vickery, Claire'
              }
            ]
          }
        ]
        expect(notifier).to have_received(:warn).with('Name type unrecognized', { type: 'primary' })
      end
    end
  end

  context 'with empty type attribute and other empty goodness' do
    let(:xml) do
      <<~XML
        <name type="">
            <namePart/>
            <role>
              <roleTerm authority="marcrelator" type="code" valueURI=""/>
            <role>
        </name>
      XML
    end

    before do
      allow(notifier).to receive(:warn).exactly(3).times
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq nil
      expect(notifier).to have_received(:warn).with('Missing or empty name type attribute')
      expect(notifier).to have_received(:warn).with('name/namePart missing value')
      expect(notifier).to have_received(:warn).with('Missing name/namePart element')
    end
  end

  # 5. Name with additional subelements
  # NOTE: this is incorrect: name identifier needs it to be "uri" and not "value" for wikidata identifier (or maybe when it's a valid uri?)
  context 'with additional subelements' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart type="termsOfAddress">Dr.</namePart>
          <namePart type="given">Terry</namePart>
          <namePart type="family">Castle</namePart>
          <namePart type="date">1953-</namePart>
          <affiliation>Stanford University</affiliation>
          <nameIdentifier type="wikidata">https://www.wikidata.org/wiki/Q7704207</nameIdentifier>
          <displayForm>Castle, Terry</displayForm>
          <description>Professor of English</description>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "structuredValue": [
                {
                  "value": 'Dr.',
                  "type": 'term of address'
                },
                {
                  "value": 'Terry',
                  "type": 'forename'
                },
                {
                  "value": 'Castle',
                  "type": 'surname'
                },
                {
                  "value": '1953-',
                  "type": 'life dates'
                }
              ]
            },
            {
              "value": 'Castle, Terry',
              "type": 'display'
            }
          ],
          "status": 'primary',
          "type": 'person',
          "identifier": [
            {
              "value": 'https://www.wikidata.org/wiki/Q7704207',
              "type": 'Wikidata'
            }
          ],
          "note": [
            {
              "value": 'Stanford University',
              "type": 'affiliation'
            },
            {
              "value": 'Professor of English',
              "type": 'description'
            }
          ]
        }
      ]
    end
  end

  # 5b. Name with untyped nameIdentifier
  # NOTE: this is incorrect: name identifier needs it to be "uri" and not "value" (as it's a valid uri?)
  context 'with missing nameIdentifier type' do
    let(:xml) do
      <<~XML
        <name type="personal">
          <namePart>Burnett, Michael W.</namePart>
          <nameIdentifier>https://orcid.org/0000-0001-5126-5568</nameIdentifier>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          identifier: [
            {
              value: 'https://orcid.org/0000-0001-5126-5568'
            }
          ],
          name: [
            {
              value: 'Burnett, Michael W.'
            }
          ],
          type: 'person'
        }
      ]
    end
  end

  context 'with namePart with empty type attribute' do
    context 'without role' do
      let(:xml) do
        <<~XML
          <name type="personal" authority="local">
            <namePart type="">Burke, Andy</namePart>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure without structuredValue and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Burke, Andy',
                "source": {
                  "code": 'local'
                }
              }
            ],
            "type": 'person'
          }
        ]
        expect(notifier).to have_received(:warn).with('Name/namePart type attribute set to ""')
      end
    end

    context 'with an invalid type on the namePart node' do
      let(:xml) do
        <<~XML
          <name>
            <namePart type="personal">Dunnett, Dorothy</namePart>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure without structuredValue and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ]
          }
        ]
        expect(notifier).to have_received(:warn).with('namePart has unknown type assigned', { type: 'personal' })
      end
    end
  end

  context 'with missing nameIdentifier type' do
    let(:xml) do
      <<~XML
        <name type="personal">
          <namePart>Burnett, Michael W.</namePart>
          <nameIdentifier>https://orcid.org/0000-0001-5126-5568</nameIdentifier>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          identifier: [
            {
              value: 'https://orcid.org/0000-0001-5126-5568'
            }
          ],
          name: [
            {
              value: 'Burnett, Michael W.'
            }
          ],
          type: 'person'
        }
      ]
    end
  end

  context 'when namePart with type but no value' do
    let(:xml) do
      <<~XML
        <name type="personal">
          <namePart>Kielmansegg, Erich Ludwig Friedrich Christian</namePart>
          <namePart type="termsOfAddress">Graf von</namePart>
          <namePart type="date">1847-1923</namePart>
          <namePart type="date"/>
        </name>
      XML
    end

    before do
      allow(notifier).to receive(:warn).once
    end

    it 'ignores the namePart with no value and warns' do
      expect(build).to eq [{ name: [{ structuredValue: [{ value: 'Kielmansegg, Erich Ludwig Friedrich Christian' },
                                                        { type: 'term of address', value: 'Graf von' },
                                                        { type: 'life dates', value: '1847-1923' }] }],
                             type: 'person' }]
      expect(notifier).to have_received(:warn).with('name/namePart missing value')
    end
  end

  context 'with role' do
    context 'with empty roleTerm' do
      let(:xml) do
        <<~XML
          <name type="personal" authority="local">
            <namePart type="">Burke, Andy</namePart>
            <role>
              <roleTerm authority="marcrelator" type="text"/>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds cocina data structure, ignoring the namePart with no value and warns' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Burke, Andy',
                "source": {
                  "code": 'local'
                }
              }
            ],
            "type": 'person'
          }
        ]
        expect(notifier).to have_received(:warn).with('Name/namePart type attribute set to ""')
        expect(notifier).to have_received(:warn).with('name/role/roleTerm missing value')
      end
    end

    context 'with a role that has no URI and has xlink uris from MODS 3.3' do
      # MODS 3.3 header from druid:yy910cj7795
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns="http://www.loc.gov/mods/v3" version="3.3"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
            <name type="personal" authority="naf" xlink:href="http://id.loc.gov/authorities/names/n82087745">
              <role>
                <roleTerm>creator</roleTerm>
              </role>
              <namePart>Tirion, Isaak</namePart>
            </name>
          </mods>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq [
          {
            name: [
              {
                value: 'Tirion, Isaak',
                uri: 'http://id.loc.gov/authorities/names/n82087745',
                source: {
                  code: 'naf'
                }
              }
            ],
            role: [
              {
                "value": 'creator'
              }
            ],
            type: 'person'
          }
        ]
        expect(notifier).to have_received(:warn).with('Name has an xlink:href property')
      end
    end

    context 'when roleTerm for type text is incorrectly capitalized' do
      let(:xml) do
        <<~XML
          <name type="corporate" usage="primary">
            <namePart>Stanford University. School of Engineering</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">Sponsor</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure with downcased role' do
        expect(build).to eq [
          {
            name: [
              {
                value: 'Stanford University. School of Engineering'
              }
            ],
            status: 'primary',
            type: 'organization',
            role: [
              {
                value: 'sponsor',
                code: 'spn',
                uri: 'http://id.loc.gov/vocabulary/relators/spn',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          }
        ]
      end
    end

    context 'with missing namePart element' do
      let(:xml) do
        <<~XML
          <name>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">Sponsor</roleTerm>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and warns' do
        expect(build).to eq nil
        expect(notifier).to have_received(:warn).with('Missing name/namePart element')
      end
    end

    context 'when the role code is missing the authority and length is not 3' do
      let(:xml) do
        <<~XML
          <name valueURI="corporate">
            <namePart>Selective Service System</namePart>
            <role>
              <roleTerm type="code">isbx</roleTerm>
            </role>
          </name>
        XML
      end

      before do
        allow(notifier).to receive(:error)
        allow(notifier).to receive(:warn)
      end

      it 'builds the cocina data structure and notifies error' do
        expect(build).to eq [
          { name: [
            { value: 'Selective Service System', uri: 'corporate' }
          ], role: [
            { code: 'isbx' }
          ] }
        ]
        expect(notifier).to have_received(:warn).with('Value URI has unexpected value', { uri: 'corporate' })
        expect(notifier).to have_received(:error).with('Contributor role code has unexpected value', { role: 'isbx' })
      end
    end
  end

  context 'with multiple names, no primary, no roles' do
    let(:xml) do
      <<~XML
        <name type="corporate">
          <namePart>Hawaii International Services Agency</namePart>
        </name>
        <name type="corporate">
          <namePart>United States</namePart>
          <namePart>Office of Foreign Investment in the United States.</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Hawaii International Services Agency'
            }
          ],
          "type": 'organization'
        },
        {
          "name": [
            {
              "structuredValue": [
                {
                  "value": 'United States'
                },
                {
                  "value": 'Office of Foreign Investment in the United States.'
                }
              ]
            }
          ],
          "type": 'organization'
        }

      ]
    end
  end

  # 13b. Transliterated name with role - needs fix to status primary
  context 'with transliterated name with role' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary" lang="jpn" script="Jpan" altRepGroup="1">
          <namePart>&#x30EC;&#x30A2;&#x30E1;&#x30BF;&#x30EB;&#x8CC7;&#x6E90;&#x518D;&#x751F;&#x6280;&#x8853;&#x7814;&#x7A76;&#x4F1A;</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/cre">cre</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/cre">creator</roleTerm>
          </role>
        </name>
        <name type="corporate" lang="jpn" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
          <namePart>Rea Metaru Shigen Saisei Gijutsu Kenky&#x16B;kai</namePart>
          <role>
            <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/cre">cre</roleTerm>
            <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/cre">creator</roleTerm>
          </role>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          name: [
            {
              parallelValue: [
                {
                  "status": 'primary',
                  "valueLanguage": {
                    "code": 'jpn',
                    "source": {
                      "code": 'iso639-2b'
                    },
                    "valueScript": {
                      "code": 'Jpan',
                      "source": {
                        "code": 'iso15924'
                      }
                    }
                  },
                  "value": 'レアメタル資源再生技術研究会'
                },
                {
                  "valueLanguage": {
                    "code": 'jpn',
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
                  "type": 'transliteration',
                  "standard": {
                    "value": 'ALA-LC Romanization Tables'
                  },
                  "value": 'Rea Metaru Shigen Saisei Gijutsu Kenkyūkai'
                }
              ],
              type: 'organization',
              status: 'primary'
            }
          ],
          role: [
            {
              "value": 'creator',
              "code": 'cre',
              "uri": 'http://id.loc.gov/vocabulary/relators/cre',
              "source": {
                "code": 'marcrelator',
                "uri": 'http://id.loc.gov/vocabulary/relators/'
              }
            }
          ]
        }
      ]
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Contributor do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, contributors: contributors, titles: titles, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  let(:titles) { nil }

  context 'when contributors is nil' do
    let(:contributors) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'with a personal name' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Dunnett, Dorothy'
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
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with empty name' do
    # see https://github.com/sul-dlss/dor-services-app/issues/1161
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": ''
            }
          ],
          "role": [
            {
              "value": ''
            }
          ]
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name>
            <namePart/>
            <role/>
          </name>
        </mods>
      XML
    end
  end

  context 'with a corporate name' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Dorothy L. Sayers Society'
            }
          ],
          "type": 'organization',
          "status": 'primary'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="corporate" usage="primary">
            <namePart>Dorothy L. Sayers Society</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with a family name' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'James family'
            }
          ],
          "type": 'family',
          "status": 'primary'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="family" usage="primary">
            <namePart>James family</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with a conference name' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Mystery Science Theater ConventioCon Expo Fest-o-rama'
            }
          ],
          "type": 'conference',
          "status": 'primary'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="conference" usage="primary">
            <namePart>Mystery Science Theater ConventioCon Expo Fest-o-rama</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with a translated name' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          {
            "name": [
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
                type: 'organization'
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
          <name type="corporate" usage="primary" lang="jpn" script="Jpan" altRepGroup="1">
            <namePart>&#x30EC;&#x30A2;&#x30E1;&#x30BF;&#x30EB;&#x8CC7;&#x6E90;&#x518D;&#x751F;&#x6280;&#x8853;&#x7814;&#x7A76;&#x4F1A;</namePart>
          </name>
          <name type="corporate" lang="jpn" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
            <namePart>Rea Metaru Shigen Saisei Gijutsu Kenky&#x16B;kai</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'without type' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Dunnett, Dorothy'
            }
          ],
          "status": 'primary'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with role' do
    context 'when both code and value' do
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            name: [
              {
                value: 'Dunnett, Dorothy'
              }
            ],
            status: 'primary',
            type: 'person',
            role: [
              {
                value: 'author',
                code: 'aut',
                uri: 'http://id.loc.gov/vocabulary/relators/aut',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end
    end

    context 'when role has code but not value' do
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ],
            "status": 'primary',
            "type": 'person',
            "role": [
              {
                "code": 'aut',
                "uri": 'http://id.loc.gov/vocabulary/relators/aut',
                "source": {
                  "code": 'marcrelator',
                  "uri": 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end
    end

    context 'when role has value but not code' do
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ],
            "status": 'primary',
            "type": 'person',
            "role": [
              {
                "value": 'author',
                "uri": 'http://id.loc.gov/vocabulary/relators/aut',
                "source": {
                  "code": 'marcrelator',
                  "uri": 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end
    end

    context 'when role has value but not code and no authority' do
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            "name": [
              {
                "value": 'Dunnett, Dorothy'
              }
            ],
            "type": 'person',
            "role": [
              {
                "value": 'Author'
              }
            ]
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <name type="personal">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text">Author</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end
    end

    context 'when role has valueURI as the only authority attribute' do
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            name: [
              {
                value: 'Dunnett, Dorothy'
              }
            ],
            status: 'primary',
            type: 'person',
            role: [
              {
                value: 'author',
                code: 'aut',
                uri: 'http://id.loc.gov/vocabulary/relators/aut'
              }
            ]
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
                <roleTerm type="code" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end
    end

    context 'when role has authority as the only authority attribute' do
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            name: [
              {
                value: 'Dunnett, Dorothy'
              }
            ],
            status: 'primary',
            type: 'person',
            role: [
              {
                value: 'author',
                code: 'aut',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ]
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/">author</roleTerm>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/">aut</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end
    end

    context 'when role and name elements are empty' do
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            "name": [
              {
                "value": ''
              }
            ],
            "role": [
              {
                "source":
                  {
                    "code": 'marcreleator'
                  }
              }
            ]
          )
        ]
      end

      it 'builds the (empty) name elements in the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <name>
              <namePart/>
              <role/>
            </name>
          </mods>
        XML
      end
    end

    context 'when multiple roles' do
      let(:contributors) do
        [
          Cocina::Models::Contributor.new(
            name: [
              {
                value: 'Dunnett, Dorothy'
              }
            ],
            status: 'primary',
            type: 'person',
            role: [
              {
                value: 'primary advisor'
              },
              {
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                },
                code: 'ths'
              }
            ]
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
                <role>
                  <roleTerm type="text">primary advisor</roleTerm>
                </role>
                <role>
                  <roleTerm authority="marcrelator" type="code" authorityURI="http://id.loc.gov/vocabulary/relators/">ths</roleTerm>
                </role>
            </name>
          </mods>
        XML
      end
    end

    context 'when contributor model is empty' do
      # NOTE for https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L324'
      #   from_fedora builds a null structure ... so we're not going to get roleTerm back

      let(:contributors) do
        [
          Cocina::Models::Contributor.new
        ]
      end

      it 'builds the (empty) xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          </mods>
        XML
      end
    end
  end

  context 'with additional subelements' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        </mods>
      XML
    end
  end

  context 'with multiple nameParts without types' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="corporate">
            <namePart>United States</namePart>
            <namePart>Office of Foreign Investment in the United States.</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with multiple contributors' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Hawaii International Services Agency'
            }
          ],
          "type": 'organization'
        ),
        Cocina::Models::Contributor.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="corporate">
            <namePart>Hawaii International Services Agency</namePart>
          </name>
          <name type="corporate">
            <namePart>United States</namePart>
            <namePart>Office of Foreign Investment in the United States.</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with ordinal' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L140'
  end

  context 'with authority' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
              uri: 'http://id.loc.gov/authorities/names/n79046044',
              source: {
                code: 'naf',
                uri: 'http://id.loc.gov/authorities/names/'
              }
            }
          ],
          status: 'primary',
          type: 'person'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="personal" usage="primary" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79046044">
            <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with authority code only' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          name: [
            {
              value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957',
              source: {
                code: 'naf'
              }
            }
          ],
          status: 'primary',
          type: 'person'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="personal" usage="primary" authority="naf">
            <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with multiple names, one primary' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Bulgakov, Mikhail'
            }
          ],
          "type": 'person',
          "status": 'primary',
          "role": [
            {
              "value": 'author'
            }
          ]
        ),
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Burgin, Diana Lewis'
            }
          ],
          "type": 'person',
          "role": [
            {
              "value": 'translator'
            }
          ]
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="personal" usage="primary">
            <namePart>Bulgakov, Mikhail</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Burgin, Diana Lewis</namePart>
            <role>
              <roleTerm type="text">translator</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end
  end

  context 'with multiple names, one primary, dates, no roles' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            "structuredValue": [
              {
                "value": 'Sarmiento, Domingo Faustino'
              },
              {
                "type": 'life dates',
                "value": '1811-1888'
              }
            ]
          ],
          "type": 'person',
          "status": 'primary'
        ),
        Cocina::Models::Contributor.new(
          "name": [
            "structuredValue": [
              {
                "value": 'Rojas, Ricardo'
              },
              {
                "type": 'life dates',
                "value": '1882-1957'
              }
            ]
          ],
          "type": 'person'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="personal" usage="primary">
            <namePart>Sarmiento, Domingo Faustino</namePart>
            <namePart type="date">1811-1888</namePart>
          </name>
          <name type="personal">
            <namePart>Rojas, Ricardo</namePart>
            <namePart type="date">1882-1957</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with multiple names, no primary' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Gaiman, Neil'
            }
          ],
          "type": 'person',
          "role": [
            {
              "value": 'author'
            }
          ]
        ),
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Pratchett, Terry'
            }
          ],
          "type": 'person',
          "role": [
            {
              "value": 'author'
            }
          ]
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="personal">
            <namePart>Gaiman, Neil</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Pratchett, Terry</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end
  end

  context 'with a personal name part of name title group' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          "name": [
            {
              "value": 'Peele, Gregory'
            }
          ],
          "type": 'person'
        ),
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
            ]
          }
        )
      ]
    end

    let(:titles) do
      [
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

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name type="personal">
            <namePart>Peele, Gregory</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with single name, no primary (pseudonym)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L454'
  end

  # Example 11
  context 'with multiple names with transliteration (name as value)' do
    let(:contributors) do
      [
        Cocina::Models::Contributor.new(
          {
            "name": [
              {
                "parallelValue": [
                  {
                    "value": 'Булгаков, Михаил Афанасьевич',
                    "valueLanguage":
                                {
                                  "valueScript": {
                                    "code": 'Cyrl',
                                    "source": {
                                      "code": 'iso15924'
                                    }
                                  }
                                },
                    "status": 'primary',
                    "uri": 'http://id.loc.gov/authorities/names/no2015139297',
                    "source": {
                      code: 'naf',
                      uri: 'http://id.loc.gov/authorities/names'
                    }
                  },
                  {
                    "value": 'Bulgakov, Mikhail Afanasʹevich',
                    "valueLanguage":
                              {
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
                    }
                  }
                ],
                "type": 'person'
              }
            ]
          }
        ),
        Cocina::Models::Contributor.new(
          {
            "name": [
              {
                "parallelValue": [
                  {
                    "value": 'Олеша, Юрий Карлович',
                    "valueLanguage":
                                {
                                  "valueScript": {
                                    "code": 'Cyrl',
                                    "source": {
                                      "code": 'iso15924'
                                    }
                                  }
                                }

                  },
                  {
                    "value": 'Olesha, I︠U︡riĭ Karlovich',
                    "valueLanguage":
                            {
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
                    }
                  }
                ],
                "type": 'person'
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
          <name usage="primary" type="personal" script="Cyrl" altRepGroup="1" authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/no2015139297">
            <namePart>&#x411;&#x443;&#x43B;&#x433;&#x430;&#x43A;&#x43E;&#x432;, &#x41C;&#x438;&#x445;&#x430;&#x438;&#x43B; &#x410;&#x444;&#x430;&#x43D;&#x430;&#x441;&#x44C;&#x435;&#x432;&#x438;&#x447;</namePart>
          </name>
          <name type="personal" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
            <namePart>Bulgakov, Mikhail Afanas&#x2B9;evich</namePart>
          </name>
          <name type="personal" script="Cyrl" altRepGroup="2">
            <namePart>&#x41E;&#x43B;&#x435;&#x448;&#x430;, &#x42E;&#x440;&#x438;&#x439; &#x41A;&#x430;&#x440;&#x43B;&#x43E;&#x432;&#x438;&#x447;</namePart>
          </name>
          <name type="personal" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="2">
            <namePart>Olesha, I&#xFE20;U&#xFE21;ri&#x12D; Karlovich</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'with transliterated name with parts (name as structuredValue)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L569'
  end

  context 'with et al.' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L639'
  end

  context 'with displayLabel' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L662'
  end

  context 'with valueURI only' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#681'
  end

  context 'with nameIdentifier only (RWO URI)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#701'
  end
end

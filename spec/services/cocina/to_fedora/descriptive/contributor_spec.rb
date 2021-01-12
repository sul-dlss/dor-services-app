# frozen_string_literal: true

require 'rails_helper'

# numbered examples from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt
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
  let(:mods_element_open) do
    <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
    XML
  end
  let(:mods_element_close) { '</mods>' }
  let(:titles) { nil }

  context 'when contributors is nil' do
    let(:contributors) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        #{mods_element_open}
        #{mods_element_close}
      XML
    end
  end

  # 1. Personal name
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
        #{mods_element_open}
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # 2. Corporate name
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
        #{mods_element_open}
          <name type="corporate" usage="primary">
            <namePart>Dorothy L. Sayers Society</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # 3. Family name
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
        #{mods_element_open}
          <name type="family" usage="primary">
            <namePart>James family</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # 4. Conference name
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
        #{mods_element_open}
          <name type="conference" usage="primary">
            <namePart>Mystery Science Theater ConventioCon Expo Fest-o-rama</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # FIXME: this example should be added to cdm (?) - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
  context 'with a translated name, no role' do
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
        #{mods_element_open}
          <name type="corporate" usage="primary" lang="jpn" script="Jpan" altRepGroup="1">
            <namePart>レアメタル資源再生技術研究会</namePart>
          </name>
          <name type="corporate" lang="jpn" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="1">
            <namePart>Rea Metaru Shigen Saisei Gijutsu Kenky&#x16B;kai</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # FIXME: this example should be added to cdm (?) - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
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
        #{mods_element_open}
          <name usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # 5. Name with additional subelements
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
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  # FIXME: this example should be added to cdm (?) - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
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
        #{mods_element_open}
          <name type="corporate">
            <namePart>United States</namePart>
            <namePart>Office of Foreign Investment in the United States.</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # 6. Name with ordinal
  context 'with ordinal' do
    xit 'TODO: 6. Name with ordinal - mods_to_cocina_name.txt#L137'
  end

  context 'with role' do
    # 7. Name with role
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
          #{mods_element_open}
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              </role>
            </name>
          #{mods_element_close}
        XML
      end
    end

    # 7b. Role text only
    #  FIXME: discrepancy - mods only has text, not code
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
          #{mods_element_open}
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              </role>
            </name>
          #{mods_element_close}
        XML
      end
    end

    # FIXME: this example should be added to cdm - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
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
          #{mods_element_open}
            <name type="personal">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text">Author</roleTerm>
              </role>
            </name>
          #{mods_element_close}
        XML
      end
    end

    # 7c. Role code only
    #  FIXME: discrepancy - mods has code only, not text
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
          #{mods_element_open}
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              </role>
            </name>
          #{mods_element_close}
        XML
      end
    end

    # 7d. Role with valueURI as the only authority attribute
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
          #{mods_element_open}
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
                <roleTerm type="code" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
              </role>
            </name>
          #{mods_element_close}
        XML
      end
    end

    # 7e. Role with authority as the only authority attribute
    # FIXME: discrepancy - our mods includes authority attribute
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
          #{mods_element_open}
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/">author</roleTerm>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/">aut</roleTerm>
              </role>
            </name>
          #{mods_element_close}
        XML
      end
    end

    # 7f, 7g: cocina model for contributor is empty :-)
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
          #{mods_element_open}
          #{mods_element_close}
        XML
      end
    end

    context 'with empty name value and empty role value' do
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

      it 'builds empty namePart and role elements in the xml' do
        expect(xml).to be_equivalent_to <<~XML
          #{mods_element_open}
            <name>
              <namePart/>
              <role/>
            </name>
          #{mods_element_close}
        XML
      end
    end

    context 'with empty name value and missing role' do
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

      it 'builds empty namePart and role elements in the xml' do
        expect(xml).to be_equivalent_to <<~XML
          #{mods_element_open}
            <name>
              <namePart/>
              <role/>
            </name>
          #{mods_element_close}
        XML
      end
    end

    # FIXME: this example should be added to cdm - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
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
          #{mods_element_open}
            <name type="personal" usage="primary">
              <namePart>Dunnett, Dorothy</namePart>
                <role>
                  <roleTerm type="text">primary advisor</roleTerm>
                </role>
                <role>
                  <roleTerm authority="marcrelator" type="code" authorityURI="http://id.loc.gov/vocabulary/relators/">ths</roleTerm>
                </role>
            </name>
          #{mods_element_close}
        XML
      end
    end
  end

  # 8. Name with authority
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
        #{mods_element_open}
          <name type="personal" usage="primary" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79046044">
            <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
          </name>
        #{mods_element_close}
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
        #{mods_element_open}
          <name type="personal" usage="primary" authority="naf">
            <namePart>Sayers, Dorothy L. (Dorothy Leigh), 1893-1957</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # 9. Multiple names, one primary
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
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  # FIXME: this example should be added to cdm ??? - see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/298
  # kind of 18, except with multiple names
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
        #{mods_element_open}
          <name type="personal" usage="primary">
            <namePart>Sarmiento, Domingo Faustino</namePart>
            <namePart type="date">1811-1888</namePart>
          </name>
          <name type="personal">
            <namePart>Rojas, Ricardo</namePart>
            <namePart type="date">1882-1957</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # 10. Multiple names, no primary
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
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  context 'with multiple names, no primary, no roles' do
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
        #{mods_element_open}
          <name type="corporate">
            <namePart>Hawaii International Services Agency</namePart>
          </name>
          <name type="corporate">
            <namePart>United States</namePart>
            <namePart>Office of Foreign Investment in the United States.</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # almost mods_to_cocina_titleInfo.txt example 6. Uniform title with authority
  # FIXME: discrepancies (see https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_titleInfo.txt#L203)
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
        #{mods_element_open}
          <name type="personal">
            <namePart>Peele, Gregory</namePart>
          </name>
        #{mods_element_close}
      XML
    end
  end

  # 11. Single name, no primary (pseudonym)
  context 'with single name, no primary (pseudonym)' do
    xit 'TODO: 11. Single name, no primary (pseudonym) - mods_to_cocina_name.txt#L473'
  end

  # 12.  Multiple names with transliteration (name as value)
  # FIXME: discrepancy - doesn't match exactly (uris); also status primary in 2 places (inside and outside parallelValue)
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
        #{mods_element_open}
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
        #{mods_element_close}
      XML
    end
  end

  # 13. Transliterated name with parts (name as structuredValue) - reference example only
  # context 'with transliterated name with parts (name as structuredValue) - reference example only' do
  #   xit 'TODO: 13. Transliterated name with parts (name as structuredValue)) - mods_to_cocina_name.txt#L583'
  # end

  # 14. Name with et al.
  context 'with et al.' do
    xit 'TODO: 14. Name with et al. - mods_to_cocina_name.txt#L650'
  end

  # 15. Name with display label
  context 'with displayLabel' do
    xit 'TODO: 15. Name with display label - mods_to_cocina_name.txt#L673'
  end

  # 16. Name with valueURI only (authority URI)
  context 'with valueURI only' do
    xit 'TODO: 16. Name with valueURI only (authority URI) - mods_to_cocina_name.txt#L693'
  end

  # 17. Name with nameIdentifier only (RWO URI)
  context 'with nameIdentifier only (RWO URI)' do
    xit 'TODO: 17. Name with nameIdentifier only (RWO URI) - mods_to_cocina_name.txt#L713'
  end

  # 18. Full name with additional subelements
  context 'with full name with additional subelements' do
    xit 'TODO: 18. Full name with additional subelements - mods_to_cocina_name.txt#L741'
  end

  # 19. Name with active date - year
  context 'with name with active date - year' do
    xit 'TODO: 19. Name with active date - year - mods_to_cocina_name.txt#L794'
  end

  # 20. Name with active date - century
  context 'with name with active date - century' do
    xit 'TODO: 20. Name with active date - century - mods_to_cocina_name.txt#L794'
  end

  # 21. Name with approximate date
  context 'with name with approximate date' do
    xit 'TODO: 21. name with approximate date - mods_to_cocina_name.txt#L820'
  end

  # 22. Name with language
  context 'with name with language' do
    xit 'TODO: 22. Name with language - mods_to_cocina_name.txt#L846'
  end
end

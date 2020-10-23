# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Contributor do
  subject(:build) { described_class.build(ng_xml) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with a personal name' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Dunnett, Dorothy</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
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
    end
  end

  context 'with a corporate name' do
    let(:xml) do
      <<~XML
        <name type="corporate" usage="primary">
          <namePart>Dorothy L. Sayers Society</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Dorothy L. Sayers Society'
            }
          ],
          "type": 'organization',
          "status": 'primary'
        }
      ]
    end
  end

  context 'with a family name' do
    let(:xml) do
      <<~XML
        <name type="family" usage="primary">
          <namePart>James family</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'James family'
            }
          ],
          "type": 'family',
          "status": 'primary'
        }
      ]
    end
  end

  context 'with a conference name' do
    let(:xml) do
      <<~XML
        <name type="conference" usage="primary">
          <namePart>Mystery Science Theater ConventioCon Expo Fest-o-rama</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "name": [
            {
              "value": 'Mystery Science Theater ConventioCon Expo Fest-o-rama'
            }
          ],
          "type": 'conference',
          "status": 'primary'
        }
      ]
    end
  end

  context 'with miscapitalized type' do
    let(:xml) do
      <<~XML
        <name type="Personal" usage="primary">
          <namePart>Dunnett, Dorothy</namePart>
        </name>
      XML
    end

    before do
      allow(Honeybadger).to receive(:notify)
    end

    it 'builds the cocina data structure' do
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
      expect(Honeybadger).to have_received(:notify).with('Notice: Contributor type incorrectly capitalized')
    end
  end

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
              "type": 'URI',
              "source": {
                "code": 'wikidata'
              }
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

  context 'with multiple nameParts without types' do
    let(:xml) do
      <<~XML
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

  context 'with multiple names' do
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

  context 'with ordinal' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L140'
  end

  context 'with role' do
    context 'when roleTerm for types code and text' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
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
                "code": 'aut',
                "uri": 'http://id.loc.gov/vocabulary/relators/aut',
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

    context 'when roleTerm is type code' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">aut</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
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
          }
        ]
      end
    end

    context 'when roleTerm is type text' do
      let(:xml) do
        <<~XML
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/aut">author</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
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
          }
        ]
      end
    end

    context 'when the role text has no authority' do
      let(:xml) do
        <<~XML
          <name type="personal">
            <namePart>Bulgakov, Mikhail</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "name": [
              {
                "value": 'Bulgakov, Mikhail'
              }
            ],
            "type": 'person',
            "role": [
              {
                "value": 'author'
              }
            ]
          }
        ]
      end
    end

    context 'when the role code is missing the authority' do
      let(:xml) do
        <<~XML
          <name valueURI="corporate">
            <namePart>Selective Service System</namePart>
            <role>
              <roleTerm type="code">isb</roleTerm>
            </role>
          </name>
        XML
      end

      it 'raises an error' do
        expect { build }.to raise_error Cocina::Mapper::InvalidDescMetadata, './mods:role/mods:roleTerm[@type="code"] is missing required authority attribute'
      end
    end

    context 'when role has valueURI as the only authority attribute' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L263'
    end

    context 'when role has authority as the only authority attribute' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L292'
    end

    context 'when role but no namepart' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L324'
    end

    context 'when roleTerm with no value and no namepart' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L333'
    end

    context 'when roleTerm element is present but namePart is blank' do
      # FIXME:  this should not have a cocina model at all, per https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L324
      let(:xml) do
        <<~XML
          <name>
            <namePart/>
            <role>
              <roleTerm authority="marcreleator" type="text"/>
            </role>
          </name>
        XML
      end

      it 'builds the (valueless) cocina data structure' do
        expect(build).to eq [
          {
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
          }
        ]
      end
    end
  end

  context 'with authority' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L342'
  end

  context 'with multiple names, one primary' do
    let(:xml) do
      <<~XML
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
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
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
        },
        {
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
        }
      ]
    end
  end

  context 'with multiple names, one primary, dates, no roles' do
    let(:xml) do
      <<~XML
        <name type="personal" usage="primary">
          <namePart>Sarmiento, Domingo Faustino</namePart>
          <namePart type="date">1811-1888</namePart>
        </name>
        <name type="personal">
          <namePart>Rojas, Ricardo</namePart>
          <namePart type="date">1882-1957</namePart>
        </name>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
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
        },
        {
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
        }
      ]
    end
  end

  context 'with multiple names, no primary' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L410'
  end

  context 'with single name, no primary (pseudonym)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L454'
  end

  context 'with multiple names with transliteration (name as value)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L472'
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

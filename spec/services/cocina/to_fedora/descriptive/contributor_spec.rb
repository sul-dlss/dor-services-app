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
        described_class.write(xml: xml, contributors: contributors)
      end
    end
  end

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

  context 'with role' do
    context 'when both code and value' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L168'
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

    context 'when role has valueURI as the only authority attribute' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L263'
    end

    context 'when role has authority as the only authority attribute' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L292'
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
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_name.txt#L342'
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

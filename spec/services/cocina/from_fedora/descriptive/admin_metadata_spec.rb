# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::AdminMetadata do
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

  context 'with recordInfo from a replayable spreadsheet' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <languageOfCataloging usage="primary">
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
            <scriptTerm type="text" authority="iso15924">Latin</scriptTerm>
            <scriptTerm type="code" authority="iso15924">Latn</scriptTerm>
          </languageOfCataloging>
          <recordContentSource authority="marcorg" authorityURI="http://id.loc.gov/vocabulary/organizations/" valueURI="http://id.loc.gov/vocabulary/organizations/cst">CSt</recordContentSource>
          <descriptionStandard authority="dacs" authorityURI="http://id.loc.gov/vocabulary/descriptionConventions/" valueURI="http://id.loc.gov/vocabulary/descriptionConventions/dacs"></descriptionStandard>
          <recordOrigin>human prepared</recordOrigin>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        "language": [
          {
            "value": 'English',
            "code": 'eng',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/eng',
            "source": {
              "code": 'iso639-2b',
              "uri": 'http://id.loc.gov/vocabulary/iso639-2/'
            },
            "script": {
              "value": 'Latin',
              "code": 'Latn',
              "source": {
                "code": 'iso15924'
              }
            }
          }
        ],
        "contributor": [
          {
            "name": [
              {
                "code": 'CSt',
                "uri": 'http://id.loc.gov/vocabulary/organizations/cst',
                "source": {
                  "code": 'marcorg',
                  "uri": 'http://id.loc.gov/vocabulary/organizations/'
                }
              }
            ],
            "type": 'organization',
            "role": [
              {
                "value": 'original cataloging agency'
              }
            ]
          }
        ],
        "standard": {
          "code": 'dacs',
          "uri": 'http://id.loc.gov/vocabulary/descriptionConventions/dacs',
          "source": {
            "uri": 'http://id.loc.gov/vocabulary/descriptionConventions/'
          }
        },
        "note": [
          {
            "type": 'record origin',
            "value": 'human prepared'
          }
        ]
      )
    end
  end

  context 'with no authority listed for scriptTerm code' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <languageOfCataloging usage="primary">
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
            <scriptTerm type="text">Latin</scriptTerm>
            <scriptTerm type="code">Latn</scriptTerm>
          </languageOfCataloging>
          <recordContentSource authority="marcorg" authorityURI="http://id.loc.gov/vocabulary/organizations/" valueURI="http://id.loc.gov/vocabulary/organizations/cst">CSt</recordContentSource>
          <descriptionStandard authority="dacs" authorityURI="http://id.loc.gov/vocabulary/descriptionConventions/" valueURI="http://id.loc.gov/vocabulary/descriptionConventions/dacs"></descriptionStandard>
          <recordOrigin>human prepared</recordOrigin>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure and sets the scriptTerm code to blank instead of nil' do
      expect(build).to eq(
        "language": [
          {
            "value": 'English',
            "code": 'eng',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/eng',
            "source": {
              "code": 'iso639-2b',
              "uri": 'http://id.loc.gov/vocabulary/iso639-2/'
            },
            "script": {
              "value": 'Latin',
              "code": 'Latn',
              "source": {
                "code": ''
              }
            }
          }
        ],
        "contributor": [
          {
            "name": [
              {
                "code": 'CSt',
                "uri": 'http://id.loc.gov/vocabulary/organizations/cst',
                "source": {
                  "code": 'marcorg',
                  "uri": 'http://id.loc.gov/vocabulary/organizations/'
                }
              }
            ],
            "type": 'organization',
            "role": [
              {
                "value": 'original cataloging agency'
              }
            ]
          }
        ],
        "standard": {
          "code": 'dacs',
          "uri": 'http://id.loc.gov/vocabulary/descriptionConventions/dacs',
          "source": {
            "uri": 'http://id.loc.gov/vocabulary/descriptionConventions/'
          }
        },
        "note": [
          {
            "type": 'record origin',
            "value": 'human prepared'
          }
        ]
      )
    end
  end

  context 'with multiple languages' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_recordInfo.txt#L70'
  end

  context 'with recordInfo converted from MARC' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <descriptionStandard>aacr</descriptionStandard>
          <recordContentSource authority="marcorg">CSt</recordContentSource>
          <recordCreationDate encoding="marc">180305</recordCreationDate>
          <recordIdentifier source="SIRSI">a12374669</recordIdentifier>
          <recordOrigin>Converted from MARCXML to MODS version 3.6 using MARC21slim2MODS3-6_SDR.xsl (SUL version 1 2018/06/13; LC Revision 1.118 2018/01/31)</recordOrigin>
          <languageOfCataloging>
            <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
          </languageOfCataloging>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        "contributor": [
          {
            "name": [
              {
                "code": 'CSt',

                "source": {
                  "code": 'marcorg'
                }
              }
            ],
            "type": 'organization',
            "role": [
              {
                "value": 'original cataloging agency'
              }
            ]
          }
        ],
        "event": [
          {
            "type": 'creation',
            "date": [
              {
                "value": '180305',
                "encoding": {
                  "code": 'marc'
                }
              }
            ]
          }
        ],
        "standard": {
          "code": 'aacr'
        },
        "identifier": [
          {
            "value": 'a12374669',
            "source": {
              "value": 'SIRSI'
            }
          }
        ],
        "note": [
          {
            "type": 'record origin',
            "value": 'Converted from MARCXML to MODS version 3.6 using MARC21slim2MODS3-6_SDR.xsl (SUL version 1 2018/06/13; LC Revision 1.118 2018/01/31)'
          }
        ],
        "language": [
          {
            "code": 'eng',
            "source": {
              "code": 'iso639-2b'
            }
          }
        ]
      )
    end
  end

  context 'with recordInfo converted from ISO 19139' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_recordInfo.txt#L213'
  end

  context 'with recordIdentifier missing source' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <recordIdentifier>a12374669</recordIdentifier>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        "identifier": [
          {
            "value": 'a12374669'
          }
        ]
      )
    end
  end

  context 'when there is no recordOrigin element (e.g. jv711gt9148)' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <recordContentSource>DOR_MARC2MODS3-3.xsl Revision 1.1</recordContentSource>
          <recordCreationDate encoding="iso8601">2011-02-08T20:00:27.321-08:00</recordCreationDate>
          <recordIdentifier source="Data Provider Digital Object Identifier">36105033329140</recordIdentifier>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          contributor: [
            {
              name: [
                {
                  code: 'DOR_MARC2MODS3-3.xsl Revision 1.1',
                  source: {}
                }
              ],
              role: [
                {
                  value: 'original cataloging agency'
                }
              ],
              type: 'organization'
            }
          ],
          event: [
            {
              date: [
                {
                  encoding: {
                    code: 'iso8601'
                  },
                  value: '2011-02-08T20:00:27.321-08:00'
                }
              ],
              type: 'creation'
            }
          ],
          identifier: [
            {
              source: {
                value: 'Data Provider Digital Object Identifier'
              },
              value: '36105033329140'
            }
          ]
        }
      )
    end
  end

  context 'when there is no encoding for the recordCreationDate' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <recordContentSource>DOR_MARC2MODS3-3.xsl Revision 1.1</recordContentSource>
          <recordCreationDate>2011-02-08T20:00:27.321-08:00</recordCreationDate>
          <recordIdentifier source="Data Provider Digital Object Identifier">36105033329140</recordIdentifier>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure setting the code to blank instead of nil' do
      expect(build).to eq(
        {
          contributor: [
            {
              name: [
                {
                  code: 'DOR_MARC2MODS3-3.xsl Revision 1.1',
                  source: {}
                }
              ],
              role: [
                {
                  value: 'original cataloging agency'
                }
              ],
              type: 'organization'
            }
          ],
          event: [
            {
              date: [
                {
                  encoding: {
                    code: ''
                  },
                  value: '2011-02-08T20:00:27.321-08:00'
                }
              ],
              type: 'creation'
            }
          ],
          identifier: [
            {
              source: {
                value: 'Data Provider Digital Object Identifier'
              },
              value: '36105033329140'
            }
          ]
        }
      )
    end
  end
end

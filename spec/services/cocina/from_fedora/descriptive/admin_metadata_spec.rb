# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::AdminMetadata do
  subject(:build) { described_class.build(resource_element: ng_xml.root) }

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
            "status": 'primary',
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

  context 'when languageOfCataloging has an capitalized (invalid) usage' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <languageOfCataloging usage="Primary">
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
          </languageOfCataloging>
        </recordInfo>
      XML
    end

    before do
      allow(Honeybadger).to receive(:notify)
    end

    it 'builds the cocina data structure and logs the error' do
      expect(build).to eq(
        "language": [
          {
            "value": 'English',
            "status": 'primary',
            "code": 'eng',
            "uri": 'http://id.loc.gov/vocabulary/iso639-2/eng',
            "source": {
              "code": 'iso639-2b',
              "uri": 'http://id.loc.gov/vocabulary/iso639-2'
            }
          }
        ]
      )
      expect(Honeybadger).to have_received(:notify).with(
        '[DATA ERROR] languageOfCataloging usage attribute is set to "Primary"',
        { tags: 'data_error' }
      )
    end
  end

  context 'with no authority listed for scriptTerm code' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <languageOfCataloging>
            <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
            <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2/" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
            <scriptTerm type="text">Latin</scriptTerm>
            <scriptTerm type="code">Latn</scriptTerm>
          </languageOfCataloging>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure and does not add a scriptTerm source instead of setting to nil' do
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
              "code": 'Latn'
            }
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
          <recordChangeDate encoding='iso8601'>20200718050001.0</recordChangeDate>
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
          },
          {
            "type": 'modification',
            "date": [
              {
                "value": '20200718050001.0',
                "encoding": {
                  "code": 'iso8601'
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

  # <mods:recordIdentifier source="SUL catalog key">6766105</mods:recordIdentifier>
  #        <mods:recordIdentifier source="oclc">3888071</mods:recordIdentifier>

  context 'when there are multiple recordIdentifiers' do
    let(:xml) do
      <<~XML
        <recordInfo>
          <recordIdentifier source="SUL catalog key">6766105</recordIdentifier>
          <recordIdentifier source="oclc">3888071</recordIdentifier>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq(
        {
          identifier: [
            {
              source: {
                value: 'SUL catalog key'
              },
              value: '6766105'
            },
            {
              source: {
                value: 'oclc'
              },
              value: '3888071'
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
          <recordCreationDate>2011-02-08T20:00:27.321-08:00</recordCreationDate>
        </recordInfo>
      XML
    end

    it 'builds the cocina data structure leaving the code off instead of setting to nil' do
      expect(build).to eq(
        {
          event: [
            {
              date: [
                {
                  value: '2011-02-08T20:00:27.321-08:00'
                }
              ],
              type: 'creation'
            }
          ]
        }
      )
    end
  end
end

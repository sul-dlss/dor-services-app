# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Event do
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

  context 'with a simple dateCreated' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCreated>1980</dateCreated>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '1980'
            }
          ]
        }
      ]
    end
  end

  context 'with a simple dateIssued (with encoding)' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateIssued encoding="w3cdtf">1928</dateIssued>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "date": [
            {
              "value": '1928',
              "encoding": {
                "code": 'w3cdtf'
              }
            }
          ]
        }
      ]
    end
  end

  context 'with a single copyrightDate' do
    let(:xml) do
      <<~XML
        <originInfo>
          <copyrightDate>1930</copyrightDate>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'copyright',
          "date": [
            {
              "value": '1930'
            }
          ]
        }
      ]
    end
  end

  context 'with a single dateCaptured (ISO 8601 encoding, keyDate)' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCaptured keyDate="yes" encoding="iso8601">20131012231249</dateCaptured>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'capture',
          "date": [
            {
              "value": '20131012231249',
              "encoding": {
                "code": 'iso8601'
              },
              "status": 'primary'
            }
          ]
        }
      ]
    end
  end

  context 'with a single dateOther' do
    describe 'with type attribute' do
      let(:xml) do
        <<~XML
          <originInfo>
            <dateOther type="Islamic">1441 AH</dateOther>
          </originInfo>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "date": [
              {
                "value": '1441 AH',
                "note": [
                  {
                    "value": 'Islamic',
                    "type": 'date type'
                  }
                ]
              }
            ]
          }
        ]
      end
    end

    describe 'without type attribute' do
      let(:xml) do
        <<~XML
          <originInfo displayLabel="Acquisition date">
            <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
          </originInfo>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "date": [
              {
                "value": '1970-11-23',
                "encoding": {
                  "code": 'w3cdtf'
                },
                "status": 'primary'
              }
            ]
          }
        ]
      end
    end
  end

  context 'with a date range' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCreated keyDate="yes" point="start">1920</dateCreated>
          <dateCreated point="end">1925</dateCreated>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "structuredValue": [
                {
                  "value": '1920',
                  "type": 'start',
                  "status": 'primary'
                },
                {
                  "value": '1925',
                  "type": 'end'
                }
              ]
            }
          ]
        }
      ]
    end
  end

  context 'with an approximate date' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCreated qualifier="approximate">1940</dateCreated>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '1940',
              "qualifier": 'approximate'
            }
          ]
        }
      ]
    end
  end

  context 'with a range plus single date' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateIssued keyDate="yes" point="start">1940</dateIssued>
          <dateIssued point="end">1945</dateIssued>
          <dateIssued>1948</dateIssued>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "date": [
            {
              "structuredValue": [
                {
                  "value": '1940',
                  "type": 'start',
                  "status": 'primary'
                },
                {
                  "value": '1945',
                  "type": 'end'
                }
              ]
            },
            {
              "value": '1948'
            }
          ]
        }
      ]
    end
  end

  context 'with multiple single dates' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateIssued keyDate="yes">1940</dateIssued>
          <dateIssued>1942</dateIssued>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "date": [
            {
              "value": '1940',
              "status": 'primary'
            },
            {
              "value": '1942'
            }
          ]
        }
      ]
    end
  end

  context 'with BCE date (edtf encoding)' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCreated encoding="edtf">-0499</dateCreated>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '-0499',
              "encoding": {
                "code": 'edtf'
              }
            }
          ]
        }
      ]
    end
  end

  context 'with multiple date types' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateIssued>1955</dateIssued>
          <copyrightDate>1940</copyrightDate>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "date": [
            {
              "value": '1955'
            }
          ]
        },
        {
          "type": 'copyright',
          "date": [
            {
              "value": '1940'
            }
          ]
        }
      ]
    end
  end

  context 'with date range, no start point' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateIssued point="end">1980</dateIssued>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "date": [
            {
              "value": '1980',
              'type': 'end'
            }
          ]
        }
      ]
    end
  end

  context 'with place text (authorized)' do
    let(:xml) do
      <<~XML
        <originInfo>
        <place authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50046557">
          <placeTerm type="text">Stanford (Calif.)</placeTerm>
        </place>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "location": [
            {
              "value": 'Stanford (Calif.)',
              "uri": 'http://id.loc.gov/authorities/names/n50046557',
              "source": {
                "code": 'naf',
                "uri": 'http://id.loc.gov/authorities/names/'
              }
            }
          ]
        }
      ]
    end
  end

  context 'with place code' do
    let(:xml) do
      <<~XML
        <originInfo>
          <place>
            <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
          <place>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "location": [
            {
              "code": 'cau',
              "uri": 'http://id.loc.gov/vocabulary/countries/cau',
              "source": {
                "code": 'marccountry',
                "uri": 'http://id.loc.gov/vocabulary/countries/'
              }
            }
          ]
        }
      ]
    end
  end

  context 'with place code and text for different places' do
    let(:xml) do
      <<~XML
        <originInfo>
          <place>
            <placeTerm type="code" authority="marccountry">enk</placeTerm>
          </place>
          <place>
            <placeTerm type="text">London</placeTerm>
          </place>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "location": [
            {
              "code": 'enk',
              "source": {
                "code": 'marccountry'
              }
            },
            {
              "value": 'London'
            }
          ]
        }
      ]
    end
  end

  describe 'publisher' do
    context 'with one' do
      let(:xml) do
        <<~XML
          <originInfo>
            <publisher>Virago</publisher>
          </originInfo>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "type": 'publication',
            "contributor": [
              {
                "name": [
                  {
                    "value": 'Virago'
                  }
                ],
                "type": 'organization',
                "role": [
                  {
                    "value": 'publisher',
                    "code": 'pbl',
                    "uri": 'http://id.loc.gov/vocabulary/relators/pbl',
                    "source": {
                      "code": 'marcrelator',
                      "uri": 'http://id.loc.gov/vocabulary/relators/'
                    }
                  }
                ]
              }
            ]
          }
        ]
      end
    end

    context 'when it is transliterated' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L772'
    end

    context 'when it is in another language' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L821'
    end

    context 'when there are multiple' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L868'
    end
  end

  context 'with edition' do
    let(:xml) do
      <<~XML
        <originInfo>
          <edition>1st ed.</edition>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "note": [
            {
              "value": '1st ed.',
              "type": 'edition'
            }
          ]
        }
      ]
    end
  end

  context 'with issuance and frequency' do
    let(:xml) do
      <<~XML
        <originInfo>
          <issuance>serial</issuance>
          <frequency>every full moon</frequency>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "note": [
            {
              "value": 'serial',
              "type": 'issuance',
              "source": {
                "value": 'MODS issuance terms'
              }
            },
            {
              "value": 'every full moon',
              "type": 'frequency'
            }
          ]
        }
      ]
    end
  end

  context 'with multiple originInfo elements for different events' do
    let(:xml) do
      <<~XML
        <originInfo eventType="creation">
          <dateCreated>1899</dateCreated>
          <place>
            <placeTerm type="text">York</placeTerm>
          </place>
        </originInfo>
        <originInfo eventType="publication">
          <dateIssued>1901</dateIssued>
          <place>
            <placeTerm type="text">London</placeTerm>
          </place>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '1899'
            }
          ],
          "location": [
            {
              "value": 'York'
            }
          ]
        },
        {
          "type": 'publication',
          "date": [
            {
              "value": '1901'
            }
          ],
          "location": [
            {
              "value": 'London'
            }
          ]
        }
      ]
    end
  end
end

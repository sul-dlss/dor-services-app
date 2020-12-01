# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Event do
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
    describe 'with type attribute on the dateOther element' do
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

      it 'notifies Honeybadger event type is missing' do
        allow(Honeybadger).to receive(:notify)
        build
        expect(Honeybadger).to have_received(:notify)
          .with('[DATA ERROR] originInfo/dateOther missing eventType', tags: 'data_error')
      end
    end

    describe 'with eventType attribute at the originInfo level' do
      let(:xml) do
        <<~XML
          <originInfo eventType="acquisition" displayLabel="Acquisition date">
            <dateOther encoding="w3cdtf">1992</dateOther>
          </originInfo>
        XML
      end

      it 'builds the cocina data structure' do
        expect(build).to eq [
          {
            "type": 'acquisition',
            "displayLabel": 'Acquisition date',
            "date": [
              {
                "value": '1992',
                "encoding": {
                  "code": 'w3cdtf'
                }
              }
            ]
          }
        ]
      end

      it 'does not notify Honeybadger' do
        allow(Honeybadger).to receive(:notify)
        build
        expect(Honeybadger).not_to have_received(:notify)
      end

      describe 'with eventType="production" dateOther type="Julian" (MODS 3.6 and before)' do
        let(:xml) do
          <<~XML
            <originInfo eventType="production">
              <dateOther type="Julian">1544-02-02</dateOther>
            </originInfo>
          XML
        end

        it 'builds the cocina data structure' do
          expect(build).to eq [
            {
              "type": 'creation',
              "date": [
                {
                  "value": '1544-02-02',
                  "note": [
                    {
                      "value": 'Julian',
                      "type": 'date type'
                    }
                  ]
                }
              ]
            }
          ]
        end

        it 'does not notify Honeybadger' do
          allow(Honeybadger).to receive(:notify)
          build
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      describe 'with eventType="production" dateCreated calendar="Julian" (MODS 3.7)' do
        let(:xml) do
          <<~XML
            <originInfo eventType="production">
              <dateCreated calendar="Julian">1544-02-02</dateCreated>
            </originInfo>
          XML
        end

        it 'builds the cocina data structure' do
          expect(build).to eq [
            {
              "type": 'creation',
              "date": [
                {
                  "value": '1544-02-02',
                  "note": [
                    {
                      "value": 'Julian',
                      "type": 'calendar'
                    }
                  ]
                }
              ]
            }
          ]
        end

        it 'does not notify Honeybadger' do
          allow(Honeybadger).to receive(:notify)
          build
          expect(Honeybadger).not_to have_received(:notify)
        end
      end
    end

    describe 'without any type attribute, with displayLabel' do
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
            "displayLabel": 'Acquisition date',
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

      it 'notifies Honeybadger event type is missing' do
        allow(Honeybadger).to receive(:notify)
        build
        expect(Honeybadger).to have_received(:notify)
          .with('[DATA ERROR] originInfo/dateOther missing eventType', tags: 'data_error')
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

  context 'with approximate date range' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L147'
  end

  context 'with date range, approximate start date only' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L177'
  end

  context 'with date range, approximate end date only' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L206'
  end

  context 'with inferred date' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L235'
  end

  context 'with questionable date' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L253'
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

  context 'with BCE date range (edtf encoding)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L345'
  end

  context 'with CE date (edtf encoding)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L378'
  end

  context 'with CE date range (edtf encoing)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L398'
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
    it 'does not notify Honeybadger (as all is ok)' do
      allow(Honeybadger).to receive(:notify)
      build
      expect(Honeybadger).not_to have_received(:notify)
    end
  end

  context 'with Julian calendar' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L457'
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

  context 'with date range, no end point' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L520'
  end

  context 'with MARC-encoded uncertain date' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L538'
  end

  context 'with Unencoded date string' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L558'
  end

  context 'with originInfo eventType matches date type' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L575'
  end

  context 'with originInfo eventType differs from date type' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L592'
  end

  context 'with originInfo eventType differs from date type, converted from MARC with multiple 264s' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L605'
  end

  context 'with place text (authorized)' do
    let(:xml) do
      <<~XML
        <originInfo>
        <place>
          <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
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
            <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
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

  context 'with place text and code for same place' do
    let(:xml) do
      <<~XML
        <originInfo>
          <place>
            <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">California</placeTerm>
            <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
          </place>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "location": [
            {
              "value": 'California',
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

    context 'with incorrect MODS from replayable spreadsheet' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L798'
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

  context 'with issuance and frequency - authorized term' do
    let(:xml) do
      <<~XML
        <originInfo>
          <issuance>multipart monograph</issuance>
          <frequency authority="marcfrequency">Annual</frequency>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "note": [
            {
              "value": 'multipart monograph',
              "type": 'issuance',
              "source": {
                "value": 'MODS issuance terms'
              }
            },
            {
              "value": 'Annual',
              "type": 'frequency',
              "source": {
                "code": 'marcfrequency'
              }
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

  context 'with multilingual' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L1128'
  end

  context 'with displayLabel' do
    let(:xml) do
      <<~XML
        <originInfo displayLabel="Origin" eventType="production">
          <place>
            <placeTerm type="text">Stanford (Calif.)</placeTerm>
          </place>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "displayLabel": 'Origin',
          "location": [
            {
              "value": 'Stanford (Calif.)'
            }
          ]
        }
      ]
    end
  end
end

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

  # example 1 from mods_to_cocina_originInfo.txt
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

  # example 2 from mods_to_cocina_originInfo.txt
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

  # example 3 from mods_to_cocina_originInfo.txt
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

  # example 4 from mods_to_cocina_originInfo.txt
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

  # example 5 from mods_to_cocina_originInfo.txt
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

  # example 5b from mods_to_cocina_originInfo.txt
  context 'with single dateOther in Gergorian calendar' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L101'
  end

  # example 6 from mods_to_cocina_originInfo.txt
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

  # example 7 from mods_to_cocina_originInfo.txt
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

  # example 8 from mods_to_cocina_originInfo.txt
  context 'with approximate date range' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L169'
  end

  # example 9 from mods_to_cocina_originInfo.txt
  context 'with date range, approximate start date only' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L199'
  end

  # example 10 from mods_to_cocina_originInfo.txt
  context 'with date range, approximate end date only' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L228'
  end

  # example 11 from mods_to_cocina_originInfo.txt
  context 'with inferred date' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L257'
  end

  # example 12 from mods_to_cocina_originInfo.txt
  context 'with questionable date' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L275'
  end

  # example 13 from mods_to_cocina_originInfo.txt
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

  # example 14 from mods_to_cocina_originInfo.txt
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

  # example 15 from mods_to_cocina_originInfo.txt
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

  # example 16 from mods_to_cocina_originInfo.txt
  context 'with BCE date range (edtf encoding)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L367'
  end

  # example 17 ? from mods_to_cocina_originInfo.txt
  context 'with CE date (edtf encoding)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L400'
  end

  # example 18 from mods_to_cocina_originInfo.txt
  context 'with CE date range (edtf encoing)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L420'
  end

  # example 19 from mods_to_cocina_originInfo.txt
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

  # example 20 from mods_to_cocina_originInfo.txt
  context 'with Julian calendar (MODS 3.6 and before)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L485'
  end

  # example 20 from mods_to_cocina_originInfo.txt
  context 'with Julian calendar (MODS 3.7 and beyond)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L508'
  end

  # example 21 from mods_to_cocina_originInfo.txt
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

  # example 22 from mods_to_cocina_originInfo.txt
  context 'with date range, no end point' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L549'
  end

  # example 23 from mods_to_cocina_originInfo.txt
  context 'with MARC-encoded uncertain date' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L567'
  end

  # example 24 from mods_to_cocina_originInfo.txt
  context 'with Unencoded date string' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L587'
  end

  # example 25 from mods_to_cocina_originInfo.txt
  context 'with originInfo eventType matches date type' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L604'
  end

  # example 26 from mods_to_cocina_originInfo.txt
  context 'with originInfo eventType differs from date type' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L621'
  end

  # example 26b from mods_to_cocina_originInfo.txt
  context 'with originInfo eventType differs from date type, converted from MARC with multiple 264s' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L634'
  end

  # example 27 from mods_to_cocina_originInfo.txt
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

  # example 28 from mods_to_cocina_originInfo.txt
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

  # example 29 from mods_to_cocina_originInfo.txt
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

  # example 30 from mods_to_cocina_originInfo.txt
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
    # example 31 from mods_to_cocina_originInfo.txt
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

    # example 32 from mods_to_cocina_originInfo.txt
    context 'when it is transliterated' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L772'
    end

    # example 33 from mods_to_cocina_originInfo.txt
    context 'when it is in another language' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L821'
    end

    # example 34 from mods_to_cocina_originInfo.txt
    context 'when there are multiple' do
      xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L868'
    end
  end

  # example 35 from mods_to_cocina_originInfo.txt
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

  # example 36 from mods_to_cocina_originInfo.txt
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

  # example 37 from mods_to_cocina_originInfo.txt
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

  context 'with issuance for a creation event' do
    let(:xml) do
      <<~XML
        <originInfo eventType="production">
          <dateCreated encoding="w3cdtf" keyDate="yes">1988-08-03</dateCreated>
          <issuance>monographic</issuance>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '1988-08-03',
              "status": 'primary',
              "encoding": {
                "code": 'w3cdtf'
              }
            }
          ],
          "note": [
            {
              "value": 'monographic',
              "type": 'issuance',
              "source": {
                "value": 'MODS issuance terms'
              }
            }
          ]
        }
      ]
    end
  end

  # example 38 from mods_to_cocina_originInfo.txt
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

  # example 39 from mods_to_cocina_originInfo.txt
  context 'with multilingual publication location, publisher, dateIssued' do
    let(:xml) do
      <<~XML
        <originInfo script="Latn" altRepGroup="1">
          <place>
            <placeTerm type="code" authority="marccountry">ja</placeTerm>
          </place>
          <place>
            <placeTerm type="text">Kyōto-shi</placeTerm>
          </place>
          <publisher>Rinsen Shoten</publisher>
          <dateIssued>Heisei 8 [1996]</dateIssued>
          <dateIssued encoding="marc">1996</dateIssued>
          <issuance>monographic</issuance>
        </originInfo>
        <originInfo script="Hani" altRepGroup="1">
          <place>
            <placeTerm type="text">京都市</placeTerm>
          </place>
          <publisher>臨川書店</publisher>
          <dateIssued>平成 8 [1996]</dateIssued>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          type: 'publication',
          location: [
            {
              parallelValue: [
                {
                  value: 'Kyōto-shi',
                  valueLanguage: {
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                },
                {
                  value: '京都市',
                  valueLanguage: {
                    valueScript: {
                      code: 'Hani',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                }
              ]
            },
            {
              code: 'ja',
              source: {
                code: 'marccountry'
              }
            }
          ],
          contributor: [
            {
              type: 'organization',
              name: [
                {
                  parallelValue: [
                    {
                      value: 'Rinsen Shoten',
                      valueLanguage: {
                        valueScript: {
                          code: 'Latn',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    },
                    {
                      value: '臨川書店',
                      valueLanguage: {
                        valueScript: {
                          code: 'Hani',
                          source: {
                            code: 'iso15924'
                          }
                        }
                      }
                    }
                  ]
                }
              ],
              role: [
                {
                  value: 'publisher',
                  code: 'pbl',
                  uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                  source: {
                    code: 'marcrelator',
                    uri: 'http://id.loc.gov/vocabulary/relators/'
                  }
                }
              ]
            }
          ],
          date: [
            {
              parallelValue: [
                {
                  value: 'Heisei 8 [1996]',
                  valueLanguage: {
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                },
                {
                  value: '平成 8 [1996]',
                  valueLanguage: {
                    valueScript: {
                      code: 'Hani',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                },
                {
                  value: '1996',
                  encoding: {
                    code: 'marc'
                  }
                }
              ]
            }
          ],
          note: [
            {
              value: 'monographic',
              type: 'issuance',
              source: { value: 'MODS issuance terms' }
            }
          ]
        }
      ]
    end
  end

  # example 40 from mods_to_cocina_originInfo.txt
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

  # example 41 from mods_to_cocina_originInfo.txt
  context 'with multiscript originInfo with eventType production' do
    let(:xml) do
      <<~XML
        <originInfo eventType="production" lang="eng" script="Latn" altRepGroup="1">
          <dateCreated keyDate="yes" encoding="w3cdtf">1999-09-09</dateCreated>
          <place>
            <placeTerm authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79076156">Moscow</placeTerm>
          </place>
        </originInfo>
        <originInfo eventType="production" lang="rus" script="Cyrl" altRepGroup="1">
        <place>
          <placeTerm>Москва</placeTerm>
        </place>
        </originInfo>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          type: 'creation',
          date: [
            {
              value: '1999-09-09',
              status: 'primary',
              encoding: {
                code: 'w3cdtf'
              }
            }
          ],
          location: [
            {
              parallelValue: [
                {
                  value: 'Moscow',
                  uri: 'http://id.loc.gov/authorities/names/n79076156',
                  source: {
                    uri: 'http://id.loc.gov/authorities/names/'
                  },
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                },
                {
                  value: 'Москва',
                  valueLanguage: {
                    code: 'rus',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: {
                      code: 'Cyrl',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                }
              ]
            }
          ]
        }
      ]
    end
  end

  # example 42 from mods_to_cocina_originInfo.txt
  context 'with multilingual edition' do
    let(:xml) do
      <<~XML
        <originInfo eventType="publication" lang="eng" script="Latn" altRepGroup="1">
          <edition>First edition</edition>
        </originInfo>
        <originInfo eventType="publication" lang="rus" script="Cyrl" altRepGroup="1">
          <edition>Первое издание</edition>
        </originInfo>
      XML
    end

    it 'builds the expected cocina data structure' do
      expect(build).to eq [
        {
          type: 'publication',
          note: [
            {
              type: 'edition',
              parallelValue: [
                {
                  value: 'First edition',
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                },
                {
                  value: 'Первое издание',
                  valueLanguage: {
                    code: 'rus',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: {
                      code: 'Cyrl',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                }
              ]
            }
          ]
        }
      ]
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Event do
  # mapping specification examples
  # from https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt

  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, events: events, id_generator: Cocina::ToFedora::Descriptive::IdGenerator.new)
      end
    end
  end

  context 'when events is nil' do
    let(:events) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  # example 1 from mods_to_cocina_originInfo.txt
  context 'when it has a single dateCreated' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            date: [
              { value: '1980' }
            ],
            type: 'creation'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="production">
            <dateCreated>1980</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 2 from mods_to_cocina_originInfo.txt
  context 'when it has a single dateIssued (with encoding)' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            date: [
              {
                value: '1928',
                encoding: {
                  code: 'w3cdtf'
                }
              }
            ],
            type: 'publication'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="publication">
            <dateIssued encoding="w3cdtf">1928</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 3 from mods_to_cocina_originInfo.txt
  context 'when it has a single copyrightDate' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            date: [
              {
                value: '1930'
              }
            ],
            type: 'copyright'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="copyright notice">
            <copyrightDate>1930</copyrightDate>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 4 from mods_to_cocina_originInfo.txt
  context 'when it has a single dateCaptured (ISO 8601 encoding, keyDate)' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            type: 'capture',
            date: [
              {
                value: '20131012231249',
                encoding: {
                  code: 'iso8601'
                },
                status: 'primary'
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
          <originInfo eventType="capture">
            <dateCaptured keyDate="yes" encoding="iso8601">20131012231249</dateCaptured>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 5 from mods_to_cocina_originInfo.txt
  context 'when it has a single dateOther' do
    describe 'with note' do
      let(:events) do
        [
          Cocina::Models::Event.new(
            {
              date: [
                {
                  value: '1441 AH',
                  note: [
                    {
                      value: 'Islamic',
                      type: 'date type'
                    }
                  ]
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
            <originInfo>
              <dateOther type="Islamic">1441 AH</dateOther>
            </originInfo>
          </mods>
        XML
      end
    end

    describe 'with eventType="acquisition"' do
      let(:events) do
        [
          Cocina::Models::Event.new(
            {
              type: 'acquisition',
              date: [
                {
                  value: '1970-11-23',
                  status: 'primary',
                  encoding:
                    {
                      code: 'w3cdtf'
                    }
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
            <originInfo eventType="acquisition">
              <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
            </originInfo>
          </mods>
        XML
      end
    end

    describe 'without note, with displayLabel' do
      let(:events) do
        [
          Cocina::Models::Event.new(
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
          )
        ]
      end

      it 'builds the xml' do
        expect(xml).to be_equivalent_to <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <originInfo displayLabel="Acquisition date">
              <dateOther keyDate="yes" encoding="w3cdtf">1970-11-23</dateOther>
            </originInfo>
          </mods>
        XML
      end
    end
  end

  # example 5b from mods_to_cocina_originInfo.txt
  context 'when it has a single dateOther in Gregorian calendar' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L101'
  end

  # example 6 from mods_to_cocina_originInfo.txt
  context 'when it has a date range' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            type: 'creation',
            date: [
              {
                structuredValue: [
                  {
                    value: '1920',
                    type: 'start',
                    status: 'primary'
                  },
                  {
                    value: '1925',
                    type: 'end'
                  }
                ]
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
          <originInfo eventType="production">
            <dateCreated keyDate="yes" point="start">1920</dateCreated>
            <dateCreated point="end">1925</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 7 from mods_to_cocina_originInfo.txt
  context 'when it has an approximate qualifer' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            date: [
              {
                value: '1940',
                qualifier: 'approximate'
              }
            ],
            type: 'creation'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="production">
            <dateCreated qualifier="approximate">1940</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 8 from mods_to_cocina_originInfo.txt
  context 'when it has an approximate date range' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            type: 'creation',
            date: [
              {
                structuredValue: [
                  {
                    value: '1940',
                    type: 'start',
                    status: 'primary',
                    qualifier: 'approximate'
                  },
                  {
                    value: '1945',
                    type: 'end',
                    qualifier: 'approximate'
                  }
                ]
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
          <originInfo eventType="production">
            <dateCreated keyDate="yes" point="start" qualifier="approximate">1940</dateCreated>
            <dateCreated point="end" qualifier="approximate">1945</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 9 from mods_to_cocina_originInfo.txt
  context 'when it has an approximate start date only' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L199'
  end

  # example 10 from mods_to_cocina_originInfo.txt
  context 'when it has an approximate end date only' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L228'
  end

  # example 11 from mods_to_cocina_originInfo.txt
  context 'when it has an inferred qualifer' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            date: [
              {
                value: '1940',
                qualifier: 'inferred'
              }
            ],
            type: 'creation'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="production">
            <dateCreated qualifier="inferred">1940</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 12 from mods_to_cocina_originInfo.txt
  context 'when it has an questionable qualifer' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            date: [
              {
                value: '1940',
                qualifier: 'questionable'
              }
            ],
            type: 'creation'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="production">
            <dateCreated qualifier="questionable">1940</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 13 from mods_to_cocina_originInfo.txt
  context 'when it has a date range and another date' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            type: 'publication',
            date: [
              {
                structuredValue: [
                  {
                    value: '1940',
                    type: 'start',
                    status: 'primary'
                  },
                  {
                    value: '1945',
                    type: 'end'
                  }
                ]
              },
              {
                value: '1948'
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
          <originInfo eventType="publication">
            <dateIssued keyDate="yes" point="start">1940</dateIssued>
            <dateIssued point="end">1945</dateIssued>
            <dateIssued>1948</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 14 from mods_to_cocina_originInfo.txt
  context 'when it has multiple single dates' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            type: 'publication',
            date: [
              {
                value: '1940',
                status: 'primary'
              },
              {
                value: '1942'
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
          <originInfo eventType="publication">
            <dateIssued keyDate="yes">1940</dateIssued>
            <dateIssued>1942</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 15 from mods_to_cocina_originInfo.txt
  context 'when it has a BCE date' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            type: 'creation',
            date: [
              {
                value: '-0499',
                encoding: {
                  code: 'edtf'
                }
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
          <originInfo eventType="production">
            <dateCreated encoding="edtf">-0499</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 16 from mods_to_cocina_originInfo.txt
  context 'when it has a BCE date range' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L367'
  end

  # example 17 from mods_to_cocina_originInfo.txt
  context 'when it has a CE date' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L400'
  end

  # example 18 from mods_to_cocina_originInfo.txt
  context 'when it has a CE date range' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L420'
  end

  # example 19 from mods_to_cocina_originInfo.txt
  context 'when it has multiple date types' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L453'
  end

  # example 20 from mods_to_cocina_originInfo.txt
  context 'when it has Julian calendar (MODS 3.6 and before)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L485'
  end

  # example 20 from mods_to_cocina_originInfo.txt
  context 'when it has Julian calendar (MODS 3.7 and beyond)' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L508'
  end

  # example 21 from mods_to_cocina_originInfo.txt
  context 'when it has date range no start point' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L531'
  end

  # example 22 from mods_to_cocina_originInfo.txt
  context 'when it has date range no end point' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L549'
  end

  # example 23 from mods_to_cocina_originInfo.txt
  context 'when it has uncertain date MARC encoded' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L567'
  end

  # example 24 from mods_to_cocina_originInfo.txt
  context 'when it has unencoded date' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L587'
  end

  # example 25 from mods_to_cocina_originInfo.txt
  context 'when eventType matches date type' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L604'
  end

  # example 26 from mods_to_cocina_originInfo.txt
  context 'when eventType differs from date type' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L621'
  end

  # example 26b from mods_to_cocina_originInfo.txt
  context 'when eventType differs from date type, converted from MARC record with multiple 264s' do
    xit 'TODO: https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_originInfo.txt#L634'
  end

  # example 27 from mods_to_cocina_originInfo.txt
  context 'when it has place text (authorized)' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo>
            <place>
              <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 28 from mods_to_cocina_originInfo.txt
  context 'when it has place code' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo>
            <place>
              <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 29 from mods_to_cocina_originInfo.txt
  context 'when it has text and code for same place' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo>
            <place>
              <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">California</placeTerm>
              <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 30 from mods_to_cocina_originInfo.txt
  context 'when it has text and code for different places' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo>
            <place>
              <placeTerm type="code" authority="marccountry">enk</placeTerm>
            </place>
            <place>
              <placeTerm type="text">London</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 31 from mods_to_cocina_originInfo.txt
  context 'when it has a publisher' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="publication">
            <publisher>Virago</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when it has a publisher that is not marcrelator' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          type: 'publication',
          contributor: [
            {
              name: [{ value: 'Stanford University Press' }],
              type: 'organization',
              role: [
                {
                  value: 'Publisher',
                  source: { value: 'Stanford self-deposit contributor types' }
                }
              ]
            }
          ]
        )
      ]
    end

    it 'builds the expected xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="publication">
            <publisher>Stanford University Press</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 32 from mods_to_cocina_originInfo.txt
  context 'when it has a publisher that is transliterated' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "type": 'publication',
          "contributor": [
            {
              "name": [
                {
                  "value": 'Institut russkoĭ literatury (Pushkinskiĭ Dom)',
                  "type": 'transliteration',
                  "standard": {
                    "value": 'ALA-LC Romanization Tables'
                  },
                  "valueLanguage": {
                    "code": 'rus',
                    "source": {
                      "code": 'iso639-2b'
                    },
                    "valueScript": {
                      "code": 'Latn',
                      "source": {
                        "code": 'iso15924'
                      }
                    }
                  }
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="publication">
            <publisher lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables">Institut russkoĭ literatury (Pushkinskiĭ Dom)</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 33 from mods_to_cocina_originInfo.txt
  context 'when it has a publisher in a different language' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "type": 'publication',
          "contributor": [
            {
              "name": [
                {
                  "value": 'СФУ',
                  "valueLanguage": {
                    "code": 'rus',
                    "source": {
                      "code": 'iso639-2b'
                    },
                    "valueScript": {
                      "code": 'Cyrl',
                      "source": {
                        "code": 'iso15924'
                      }
                    }
                  }
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="publication">
            <publisher lang="rus" script="Cyrl">СФУ</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 34 from mods_to_cocina_originInfo.txt
  context 'when it has multiple publishers' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "type": 'publication',
          "contributor": [
            {
              "name": [
                {
                  "value": 'Ardis'
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
            },
            {
              "name": [
                {
                  "value": 'Commonplace Books'
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="publication">
            <publisher>Ardis</publisher>
            <publisher>Commonplace Books</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 35 from mods_to_cocina_originInfo.txt
  context 'with edition' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "type": 'publication',
          "note": [
            {
              "value": '1st ed.',
              "type": 'edition'
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
          <originInfo eventType="publication">
            <edition>1st ed.</edition>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 36 from mods_to_cocina_originInfo.txt
  context 'with issuance and frequency' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="publication">
            <issuance>serial</issuance>
            <frequency>every full moon</frequency>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 37 from mods_to_cocina_originInfo.txt
  context 'with issuance and frequency for authorized terms' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="publication">
            <issuance>multipart monograph</issuance>
            <frequency authority="marcfrequency">Annual</frequency>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 38 from mods_to_cocina_originInfo.txt
  context 'with multiple events' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        ),
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="production">
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
        </mods>
      XML
    end
  end

  context 'with multiple events and missing event type' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        ),
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo eventType="production">
            <dateCreated>1899</dateCreated>
            <place>
              <placeTerm type="text">York</placeTerm>
            </place>
          </originInfo>
          <originInfo>
            <dateOther>1901</dateOther>
            <place>
              <placeTerm type="text">London</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 39 from mods_to_cocina_originInfo.txt
  context 'with event represented in multiple languages' do
    let(:events) do
      [
        Cocina::Models::Event.new(
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
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <originInfo script="Latn" altRepGroup="0" eventType="publication">
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
          <originInfo script="Hani" altRepGroup="0" eventType="publication">
            <place>
              <placeTerm type="text">京都市</placeTerm>
            </place>
            <publisher>臨川書店</publisher>
            <dateIssued>平成 8 [1996]</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when event location missing source' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "location": [
            {
              "code": 'xxu'
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
          <originInfo>
            <place>
              <placeTerm type="code">xxu</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when event location with code missing source' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "location": [
            {
              "code": 'cau',
              "uri": 'http://id.loc.gov/vocabulary/countries/cau'
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
          <originInfo>
            <place>
              <placeTerm type="code" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when event location with value missing source' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          "location": [
            {
              "value": 'California',
              "uri": 'http://id.loc.gov/vocabulary/countries/cau'
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
          <originInfo>
            <place>
              <placeTerm type="text" valueURI="http://id.loc.gov/vocabulary/countries/cau">California</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  # example 40 from mods_to_cocina_originInfo.txt
  context 'when it has a displayLabel' do
    let(:events) do
      [
        Cocina::Models::Event.new(
          {
            "type": 'creation',
            "displayLabel": 'Origin',
            "location": [
              {
                "value": 'Stanford (Calif.)'
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
          <originInfo displayLabel="Origin" eventType="production">
            <place>
              <placeTerm type="text">Stanford (Calif.)</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end
end

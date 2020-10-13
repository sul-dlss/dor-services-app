# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Event do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, events: events)
      end
    end
  end

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
          <originInfo>
            <dateCreated>1980</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
            <dateIssued encoding="w3cdtf">1928</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
            <copyrightDate>1930</copyrightDate>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
            <dateCaptured keyDate="yes" encoding="iso8601">20131012231249</dateCaptured>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when it has a single dateOther' do
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
          <originInfo>
            <dateCreated keyDate="yes" point="start">1920</dateCreated>
            <dateCreated point="end">1925</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
            <dateCreated qualifier="approximate">1940</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
          <dateCreated keyDate="yes" point="start" qualifier="approximate">1940</dateCreated>
          <dateCreated point="end" qualifier="approximate">1945</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
            <dateCreated qualifier="inferred">1940</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
            <dateCreated qualifier="questionable">1940</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
            <dateIssued keyDate="yes" point="start">1940</dateIssued>
            <dateIssued point="end">1945</dateIssued>
            <dateIssued>1948</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
            <dateIssued keyDate="yes">1940</dateIssued>
            <dateIssued>1942</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end

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
          <originInfo>
            <dateCreated encoding="edtf">-0499</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

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
            <place authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50046557">
              <placeTerm type="text">Stanford (Calif.)</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

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
end

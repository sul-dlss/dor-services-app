# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive do
  subject(:xml) { described_class.transform(descriptive).to_xml }

  context 'when the title is a basic value' do
    let(:descriptive) do
      Cocina::Models::Description.new(
        title: [
          { value: 'Gaudy night' }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>Gaudy night</title>
          </titleInfo>
        </mods>
      XML
    end
  end

  context 'when the title has a structured value' do
    let(:descriptive) do
      Cocina::Models::Description.new(
        title: [
          { structuredValue: [{ type: 'nonsorting characters', value: 'The' },
                              { type: 'main title', value: 'journal of stuff' },
                              { type: 'part number', value: 'volume 5' },
                              { type: 'part name', value: 'special issue' },
                              { note: [{ type: 'nonsorting character count', value: '4' }] }] }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <nonSort>The</nonSort>
            <title>journal of stuff</title>
            <partNumber>volume 5</partNumber>
            <partName>special issue</partName>
          </titleInfo>
        </mods>
      XML
    end
  end

  context 'when the title has an alternative' do
    let(:descriptive) do
      Cocina::Models::Description.new(
        title: [
          {
            value: 'Five red herrings',
            status: 'primary'
          },
          {
            value: 'Suspicious characters',
            type: 'alternative'
          }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo usage="primary">
            <title>Five red herrings</title>
          </titleInfo>
          <titleInfo type="alternative">
            <title>Suspicious characters</title>
          </titleInfo>
        </mods>
      XML
    end
  end

  context 'when the title is translated' do
    let(:descriptive) do
      Cocina::Models::Description.new(
        title: [
          {
            "parallelValue": [
              {
                "structuredValue": [
                  {
                    "value": 'Les',
                    "type": 'nonsorting characters'
                  },
                  {
                    "value": 'misérables',
                    "type": 'main title'
                  },
                  {
                    "note": [
                      {
                        "value": '4',
                        "type": 'nonsorting character count'
                      }
                    ]
                  }
                ],
                "status": 'primary',
                "valueLanguage": {
                  "code": 'fre',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              },
              {
                "structuredValue": [
                  {
                    "value": 'The',
                    "type": 'nonsorting characters'
                  },
                  {
                    "value": 'wretched',
                    "type": 'main title'
                  },
                  {
                    "note": [
                      {
                        "value": '4',
                        "type": 'nonsorting character count'
                      }
                    ]
                  }
                ],
                "type": 'translated',
                "valueLanguage": {
                  "code": 'eng',
                  "source": {
                    "code": 'iso639-2b'
                  }
                }
              }
            ]
          }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo usage="primary" lang="fre" altRepGroup="0">
            <nonSort>Les</nonSort>
            <title>mis&#xE9;rables</title>
          </titleInfo>
          <titleInfo type="translated" lang="eng" altRepGroup="0">
            <nonSort>The</nonSort>
            <title>wretched</title>
          </titleInfo>
        </mods>
      XML
    end
  end
end

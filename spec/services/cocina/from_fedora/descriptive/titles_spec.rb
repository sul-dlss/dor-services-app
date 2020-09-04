# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Titles do
  let(:object) { Dor::Item.new }

  describe '.build' do
    subject(:build) { described_class.build(ng_xml) }

    context 'when the object has no title' do
      let(:ng_xml) { Dor::Item.new.descMetadata.ng_xml }

      it 'raises and error' do
        expect { build }.to raise_error Cocina::Mapper::MissingTitle
      end
    end

    context 'when the title has parts' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
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

      it 'is a structured value' do
        expect(build).to eq [
          { structuredValue: [{ type: 'nonsorting characters', value: 'The' },
                              { type: 'main title', value: 'journal of stuff' },
                              { type: 'part number', value: 'volume 5' },
                              { type: 'part name', value: 'special issue' },
                              { note: [{ type: 'nonsorting character count', value: 4 }] }] }
        ]
      end
    end

    context 'when there is an alternative title' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
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

      it 'has alternative type' do
        expect(build).to eq [
          { status: 'primary', value: 'Five red herrings' },
          { type: 'alternative', value: 'Suspicious characters' }
        ]
      end
    end

    context 'when there is a translated title (title is structuredValue)' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo usage="primary" lang="fre" altRepGroup="0">
              <nonSort>Les</nonSort>
              <title>misérables</title>
            </titleInfo>
            <titleInfo type="translated" lang="eng" altRepGroup="0">
              <nonSort>The</nonSort>
              <title>wretched</title>
            </titleInfo>
          </mods>
        XML
      end

      it 'creates parallelValues' do
        expect(build).to eq [
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
                        "value": 4,
                        "type": 'nonsorting character count'
                      }
                    ]
                  }
                ],
                "status": 'primary',
                "language": [
                  {
                    "code": 'fre',
                    "source": {
                      "code": 'iso639-2b'
                    }
                  }
                ]
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
                        "value": 4,
                        "type": 'nonsorting character count'
                      }
                    ]
                  }
                ],
                "type": 'translated',
                "language": [
                  {
                    "code": 'eng',
                    "source": {
                      "code": 'iso639-2b'
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
end

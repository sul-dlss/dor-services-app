# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Note do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, notes: [note])
      end
    end
  end

  context 'when it has a simple abstract' do
    let(:note) do
      Cocina::Models::DescriptiveValue.new(
        {
          value: 'This is an abstract.',
          type: 'summary'
        }
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <abstract>This is an abstract.</abstract>
        </mods>
      XML
    end
  end

  context 'when it has a multilingual abstract' do
    let(:note) do
      Cocina::Models::DescriptiveValue.new(
        {
          "type": 'summary',
          "parallelValue": [
            {
              "value": 'This is an abstract.',
              "valueLanguage": {
                "code": 'eng',
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
            },
            {
              "value": 'Это аннотация.',
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
          ]
        }
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <abstract lang="eng" script="Latn" altRepGroup="0">This is an abstract.</abstract>
          <abstract lang="rus" script="Cyrl" altRepGroup="0">&#x42D;&#x442;&#x43E; &#x430;&#x43D;&#x43D;&#x43E;&#x442;&#x430;&#x446;&#x438;&#x44F;.</abstract>
        </mods>
      XML
    end
  end

  context 'when it has a display label' do
    let(:note) do
      Cocina::Models::DescriptiveValue.new(
        {
          "value": 'This is a synopsis.',
          "type": 'summary',
          "displayLabel": 'Synopsis'
        }
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <abstract displayLabel="Synopsis">This is a synopsis.</abstract>
        </mods>
      XML
    end
  end
end

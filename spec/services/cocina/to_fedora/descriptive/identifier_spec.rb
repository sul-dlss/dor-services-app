# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Identifier do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, identifiers: identifiers)
      end
    end
  end

  # 0: Identifier is nil
  context 'when identifiers is nil' do
    let(:identifiers) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  # 1. Identifier with type
  context 'when it has a single identifier with type' do
    let(:identifiers) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": '1234 5678 9203',
            "type": 'ISBN',
            "note": [
              {
                "type": 'type',
                "value": 'isbn',
                "uri": 'http://id.loc.gov/vocabulary/identifiers/isbn',
                "source": {
                  "value": 'Standard Identifier Schemes',
                  "uri": 'http://id.loc.gov/vocabulary/identifiers/'
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
          <identifier type="isbn">1234 5678 9203</identifier>
        </mods>
      XML
    end
  end

  # 2. URI as identifier
  context 'when it has a URI as identifier' do
    let(:identifiers) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "uri": 'https://www.wikidata.org/wiki/Q146',
            "note": [
              {
                "type": 'type',
                "value": 'uri',
                "uri": 'http://id.loc.gov/vocabulary/identifiers/uri',
                "source": {
                  "value": 'Standard Identifier Schemes',
                  "uri": 'http://id.loc.gov/vocabulary/identifiers/'
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
          <identifier type="uri">https://www.wikidata.org/wiki/Q146</identifier>
        </mods>
      XML
    end
  end

  # 3. Identifier with display label
  context 'when it has an Identifier with display label' do
    let(:identifiers) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": '1980-12345',
            "displayLabel": 'Accession number'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <identifier displayLabel="Accession number">1980-12345</identifier>
        </mods>
      XML
    end
  end

  # 4. Invalid identifier
  context 'when it is an Invalid identifier' do
    let(:identifiers) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'sn 87042262',
          "status": 'invalid',
          "type": 'LCCN',
          "note": [
            {
              "type": 'type',
              "value": 'lccn',
              "uri": 'http://id.loc.gov/vocabulary/identifiers/lccn',
              "source": {
                "value": 'Standard Identifier Schemes',
                "uri": 'http://id.loc.gov/vocabulary/identifiers/'
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
          <identifier type="lccn" invalid="yes">sn 87042262</identifier>
        </mods>
      XML
    end
  end

  # FIXME:  https://github.com/sul-dlss-labs/cocina-descriptive-metadata/issues/320
  context 'when it has a single identifier that does not match a MODS term' do
    let(:identifiers) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": '123456789203',
            "type": 'OCLC'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <identifier type="OCLC">123456789203</identifier>
        </mods>
      XML
    end
  end
end

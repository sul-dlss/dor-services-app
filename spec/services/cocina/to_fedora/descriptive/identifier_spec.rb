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

  context 'when it has a single identifier' do
    let(:identifiers) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "value": '1234 5678 9203',
            "type": 'ISBN'
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

  context 'when it has a URI identifier' do
    let(:identifiers) do
      [
        Cocina::Models::DescriptiveValue.new(
          {
            "type": 'URI',
            "value": 'https://www.wikidata.org/wiki/Q146'
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

  context 'when it has a display label' do
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

  context 'when it is invalid' do
    let(:identifiers) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": '1234 5678 9203',
          "status": 'invalid',
          "type": 'ISBN'
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <identifier type="isbn" invalid="yes">1234 5678 9203</identifier>
        </mods>
      XML
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Identifier do
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

  context 'with an identifier with a type' do
    let(:xml) do
      <<~XML
        <identifier type="isbn">1234 5678 9203</identifier>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": '1234 5678 9203',
          "type": 'ISBN'
        }
      ]
    end
  end

  context 'with URI as an identifier' do
    let(:xml) do
      <<~XML
        <identifier type="uri">https://www.wikidata.org/wiki/Q146</identifier>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'https://www.wikidata.org/wiki/Q146',
          "type": 'URI'
        }
      ]
    end
  end

  context 'with display label' do
    let(:xml) do
      <<~XML
        <identifier displayLabel="Accession number">1980-12345</identifier>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": '1980-12345',
          "displayLabel": 'Accession number'
        }
      ]
    end
  end
end

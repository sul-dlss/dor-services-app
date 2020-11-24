# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModsEquivalentService do
  let(:result) { described_class.equivalent?(mods_ng_xml1, mods_ng_xml2) }

  let(:mods_ng_xml1) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        <titleInfo>
          <title>journal of stuff</title>
        </titleInfo>
        <identifier type="uri">https://www.wikidata.org/wiki/Q146</identifier>
        <identifier displayLabel="Accession number">1980-12345</identifier>
      </mods>
    XML
  end

  context 'when equivalent' do
    let(:mods_ng_xml2) { mods_ng_xml1 }

    it 'returns success' do
      expect(result.success?).to be(true)
    end
  end

  context 'when missing a node' do
    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>journal of stuff</title>
          </titleInfo>
          <identifier type="uri">https://www.wikidata.org/wiki/Q146</identifier>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be(true)
    end

    it 'returns diff' do
      expect(result.failure.size).to eq(1)
      expect(result.failure.first.mods_node1.to_s).to eq('<identifier displayLabel="Accession number">1980-12345</identifier>')
      expect(result.failure.first.mods_node2).to eq(nil)
    end
  end

  context 'when mismatch and only one node with tag' do
    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>journal of broken stuff</title>
          </titleInfo>
          <identifier type="uri">https://www.wikidata.org/wiki/Q146</identifier>
          <identifier displayLabel="Accession number">1980-12345</identifier>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be(true)
    end

    it 'returns diff' do
      expect(result.failure.size).to eq(1)
      expect(result.failure.first.mods_node1.canonicalize).to eq(
        <<~XML.chomp
          <titleInfo xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <title>journal of stuff</title>
            </titleInfo>
        XML
      )
      expect(result.failure.first.mods_node2.canonicalize).to eq(
        <<~XML.chomp
          <titleInfo xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
              <title>journal of broken stuff</title>
            </titleInfo>
        XML
      )
    end
  end

  context 'when mismatch and multiple nodes with tag' do
    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>journal of stuff</title>
          </titleInfo>
          <identifier type="uri">xhttps://www.wikidata.org/wiki/Q146</identifier>
          <identifier displayLabel="Accession number">1980-12345</identifier>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be(true)
    end

    it 'returns diff' do
      expect(result.failure.size).to eq(1)
      expect(result.failure.first.mods_node1.to_s).to eq('<identifier type="uri">https://www.wikidata.org/wiki/Q146</identifier>')
      expect(result.failure.first.mods_node2.to_s).to eq('<identifier type="uri">xhttps://www.wikidata.org/wiki/Q146</identifier>')
    end
  end
end

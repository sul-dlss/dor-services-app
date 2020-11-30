# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModsEquivalentService do
  let(:result) { described_class.equivalent_with_result?(mods_ng_xml1, mods_ng_xml2) }

  let(:bool_result) { described_class.equivalent?(mods_ng_xml1, mods_ng_xml2) }

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

    it 'returns true' do
      expect(bool_result).to be(true)
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

    it 'returns false' do
      expect(bool_result).to be(false)
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

    it 'returns false' do
      expect(bool_result).to be(false)
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

    it 'returns false' do
      expect(bool_result).to be(false)
    end
  end

  context 'when matching altRepGroup with different ids' do
    let(:mods_ng_xml1) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note lang="eng" altRepGroup="1">This is a note.</note>
          <note lang="fre" altRepGroup="1">C'est une note.</note>
        </mods>
      XML
    end

    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note lang="eng" altRepGroup="2">This is a note.</note>
          <note lang="fre" altRepGroup="2">C'est une note.</note>
        </mods>
      XML
    end

    it 'returns success' do
      expect(result.success?).to be(true)
    end

    it 'returns true' do
      expect(bool_result).to be(true)
    end
  end

  context 'when missing altRepGroup' do
    let(:mods_ng_xml1) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note lang="eng" altRepGroup="1">This is a note.</note>
          <note lang="fre" altRepGroup="1">C'est une note.</note>
        </mods>
      XML
    end

    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note lang="eng">This is a note.</note>
          <note lang="fre">C'est une note.</note>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be(true)
    end

    it 'returns diff' do
      expect(result.failure.size).to eq(2)
      expect(result.failure.first.mods_node1.to_s).to eq('<note lang="eng" altRepGroup="1">This is a note.</note>')
      expect(result.failure.first.mods_node2.to_s).to eq('<note lang="eng">This is a note.</note>')
    end

    it 'returns false' do
      expect(bool_result).to be(false)
    end
  end

  context 'when mismatched altRepGroup with different ids' do
    let(:mods_ng_xml1) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note lang="eng" altRepGroup="1">This is a note.</note>
          <note lang="fre" altRepGroup="1">C'est une note.</note>
        </mods>
      XML
    end

    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note lang="eng" altRepGroup="2">This is a note.</note>
          <note lang="fre" altRepGroup="3">C'est une note.</note>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be(true)
    end

    it 'returns diff' do
      expect(result.failure.size).to eq(1)
      expect(result.failure.first.mods_node1.to_s).to eq('<note lang="eng" altRepGroup="1">This is a note.</note>')
      expect(result.failure.first.mods_node2.to_s).to eq('<note lang="eng" altRepGroup="2">This is a note.</note>')
    end

    it 'returns false' do
      expect(bool_result).to be(false)
    end
  end

  context 'when matching nameTitleGroup with different ids' do
    let(:mods_ng_xml1) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo nameTitleGroup="0">
            <title>Hamlet</title>
          </titleInfo>
          <name nameTitleGroup="0">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
        </mods>
      XML
    end

    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo nameTitleGroup="1">
            <title>Hamlet</title>
          </titleInfo>
          <name nameTitleGroup="1">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
        </mods>
      XML
    end

    it 'returns success' do
      expect(result.success?).to be(true)
    end

    it 'returns true' do
      expect(bool_result).to be(true)
    end
  end

  context 'when missing nameTitleGroup' do
    let(:mods_ng_xml1) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo nameTitleGroup="0">
            <title>Hamlet</title>
          </titleInfo>
          <name nameTitleGroup="0">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
        </mods>
      XML
    end

    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>Hamlet</title>
          </titleInfo>
          <name>
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be(true)
    end

    it 'returns diff' do
      expect(result.failure.size).to eq(2)
      expect(result.failure.first.mods_node1.to_s).to eq("<titleInfo nameTitleGroup=\"0\">\n    <title>Hamlet</title>\n  </titleInfo>")
      expect(result.failure.first.mods_node2.to_s).to eq("<titleInfo>\n    <title>Hamlet</title>\n  </titleInfo>")
    end

    it 'returns false' do
      expect(bool_result).to be(false)
    end
  end

  context 'when mismatched nameTitleGroup with different ids' do
    let(:mods_ng_xml1) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo nameTitleGroup="0">
            <title>Hamlet</title>
          </titleInfo>
          <name nameTitleGroup="0">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
        </mods>
      XML
    end

    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo nameTitleGroup="1">
            <title>Hamlet</title>
          </titleInfo>
          <name nameTitleGroup="2">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be(true)
    end

    it 'returns diff' do
      expect(result.failure.size).to eq(1)
      expect(result.failure.first.mods_node1.to_s).to eq("<titleInfo nameTitleGroup=\"0\">\n    <title>Hamlet</title>\n  </titleInfo>")
      expect(result.failure.first.mods_node2.to_s).to eq("<titleInfo nameTitleGroup=\"1\">\n    <title>Hamlet</title>\n  </titleInfo>")
    end

    it 'returns false' do
      expect(bool_result).to be(false)
    end
  end

  context 'when matching nameTitleGroup and altRepGroup' do
    let(:mods_ng_xml1) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo type="uniform" nameTitleGroup="01" altRepGroup="01">
            <title>Mishnah berurah. English and Hebrew</title>
          </titleInfo>
          <name type="personal" usage="primary" altRepGroup="02" nameTitleGroup="01">
            <namePart>Israel Meir</namePart>
            <namePart type="termsOfAddress">ha-Kohen</namePart>
            <namePart type="date">1838-1933</namePart>
          </name>
          <name type="personal" usage="primary" altRepGroup="02" nameTitleGroup="02">
            <namePart>Israel Meir in Hebrew characters</namePart>
            <namePart type="date">1838-1933</namePart>
          </name>
          <titleInfo type="uniform" nameTitleGroup="02" altRepGroup="01">
            <title>Mishnah berurah in Hebrew characters</title>
          </titleInfo>
        </mods>
      XML
    end

    let(:mods_ng_xml2) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo type="uniform" nameTitleGroup="1" altRepGroup="1">
            <title>Mishnah berurah. English and Hebrew</title>
          </titleInfo>
          <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="1">
            <namePart>Israel Meir</namePart>
            <namePart type="termsOfAddress">ha-Kohen</namePart>
            <namePart type="date">1838-1933</namePart>
          </name>
          <name type="personal" usage="primary" altRepGroup="2" nameTitleGroup="2">
            <namePart>Israel Meir in Hebrew characters</namePart>
            <namePart type="date">1838-1933</namePart>
          </name>
          <titleInfo type="uniform" nameTitleGroup="2" altRepGroup="1">
            <title>Mishnah berurah in Hebrew characters</title>
          </titleInfo>
        </mods>
      XML
    end

    it 'returns success' do
      expect(result.success?).to be(true)
    end

    it 'returns true' do
      expect(bool_result).to be(true)
    end
  end
end

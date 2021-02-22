# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ModsNormalizers::NameNormalizer do
  let(:normalized_ng_xml) { Cocina::ModsNormalizer.normalize(mods_ng_xml: mods_ng_xml, druid: nil, label: nil).to_xml }

  context 'when the role term has no type' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm>photographer</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end

    it 'add type="text"' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="text">photographer</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end
  end

  context 'when the roleTerm is empty and no valueURI or URI attribute' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name type="personal" authority="local">
            <namePart>Burke, Andy</namePart>
            <role>
              <roleTerm authority="marcrelator" type="text"/>
            </role>
          </name>
        </mods>
      XML
    end

    it 'removes the roleTerm (and role, if empty)' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name type="personal" authority="local">
            <namePart>Burke, Andy</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'when the role has no subelement, no attributes' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name type="personal" authority="local">
            <namePart>Burke, Andy</namePart>
            <role>
            </role>
          </name>
        </mods>
      XML
    end

    it 'removes the role' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name type="personal" authority="local">
            <namePart>Burke, Andy</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'when normalizing empty names' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name>
            <namePart/>
            <role>
              <roleTerm authority="marcrelator" type="text">author</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end

    it 'removes name' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
        </mods>
      XML
    end
  end

  context 'with missing namePart element' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">spn</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/spn">Sponsor</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end

    it 'removes name' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
        </mods>
      XML
    end
  end

  context 'when name has xlink:href' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES} xmlns:xlink="http://www.w3.org/1999/xlink">
          <name type="personal" authority="naf" xlink:href="http://id.loc.gov/authorities/names/n82087745">
            <namePart>Tirion, Isaak</namePart>
          </name>
        </mods>
      XML
    end

    it 'is converted to valueURI' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name type="personal" authority="naf" valueURI="http://id.loc.gov/authorities/names/n82087745">
            <namePart>Tirion, Isaak</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'when duplicate names' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
          </name>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
          </name>
          <relatedItem>
            <name>
              <namePart>Dunnett, Dorothy</namePart>
            </name>
            <name>
              <namePart>Dunnett, Dorothy</namePart>
            </name>
          </relatedItem>
        </mods>
      XML
    end

    it 'duplicates are removed' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
          </name>
          <relatedItem>
            <name>
              <namePart>Dunnett, Dorothy</namePart>
            </name>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when name@type value incorrectly capitalized' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name type="Personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        </mods>
      XML
    end

    it 'corrects value to lower case' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name type="personal" usage="primary">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'when name@type not recognized' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name type="fred">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        </mods>
      XML
    end

    it 'removes type attribute' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'when namePart has a invalid type attribute' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name>
            <namePart type="personal">Dunnett, Dorothy</namePart>
          </name>
        </mods>
      XML
    end

    it 'removes invalid type attribute' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        </mods>
      XML
    end
  end
end

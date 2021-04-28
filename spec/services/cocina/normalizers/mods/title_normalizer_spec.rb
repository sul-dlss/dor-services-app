# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::Mods::TitleNormalizer do
  let(:normalized_ng_xml) { Cocina::Normalizers::ModsNormalizer.normalize(mods_ng_xml: mods_ng_xml, druid: nil, label: label).to_xml }

  let(:label) { nil }

  context 'when normalizing empty title' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo>
            <title />
            <subTitle/>
          </titleInfo>
        </mods>
      XML
    end

    it 'removes titleInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
        </mods>
      XML
    end
  end

  context 'when normalizing Hydrus title' do
    let(:label) { 'Hydrus' }

    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo>
            <title />
          </titleInfo>
        </mods>
      XML
    end

    it 'adds Hydrus titleInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo>
            <title>Hydrus</title>
          </titleInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing titles with type' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo>
            <title type="main">Monaco Grand Prix</title>
          </titleInfo>
        </mods>
      XML
    end

    it 'removes type' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo>
            <title>Monaco Grand Prix</title>
          </titleInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing title trailing characters' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo>
            <title>Syntactic Structures,</title>
          </titleInfo>
          <titleInfo>
            <title>Requiem for the American Dream.</title>
          </titleInfo>
          <titleInfo type="abbreviated">
            <title>Refl. on Lang.</title>
          </titleInfo>
        </mods>
      XML
    end

    it 'removes trailing comma and period' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo>
            <title>Syntactic Structures</title>
          </titleInfo>
          <titleInfo>
            <title>Requiem for the American Dream</title>
          </titleInfo>
          <titleInfo type="abbreviated">
            <title>Refl. on Lang.</title>
          </titleInfo>
        </mods>
      XML
    end
  end
end

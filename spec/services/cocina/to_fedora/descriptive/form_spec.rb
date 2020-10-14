# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Form do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, forms: forms)
      end
    end
  end

  context 'when form is nil' do
    let(:forms) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'with an object with one type' do
    let(:forms) do
      [
        Cocina::Models::DescriptiveValue.new(
          "value": 'text',
          "type": 'resource type',
          "source": {
            "value": 'MODS resource type'
          }
        )
      ]
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <typeOfResource>text</typeOfResource>
        </mods>
      XML
    end
  end

  context 'with an object with multiple types' do
    xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L17'
  end

  context 'with an object with multiple types and one predominant' do
    xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L39'
  end

  context 'with a manuscript' do
    xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L62'
  end

  context 'with an sttribute without a value' do
    xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L79'
  end

  context 'with a collection' do
    xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L89'
  end

  context 'with display label' do
    xit 'https://github.com/sul-dlss-labs/cocina-descriptive-metadata/blob/master/mods_cocina_mappings/mods_to_cocina_typeOfResource.txt#L106'
  end
end

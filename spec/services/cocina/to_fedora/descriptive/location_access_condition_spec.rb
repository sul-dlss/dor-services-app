# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive::Location do
  subject(:xml) { writer.to_xml }

  let(:writer) do
    Nokogiri::XML::Builder.new do |xml|
      xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
               'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
               'version' => '3.6',
               'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
        described_class.write(xml: xml, access: access, purl: nil)
      end
    end
  end

  context 'when access_conditions is nil' do
    let(:access) { nil }

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        </mods>
      XML
    end
  end

  context 'when it is a restriction on access' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "note": [
          {
            "value": 'Available to Stanford researchers only.',
            "type": 'access restriction'
          }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <accessCondition type="restriction on access">Available to Stanford researchers only.</accessCondition>
        </mods>
      XML
    end
  end

  context 'when it is a restriction on use and reproduction' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "note": [
          {
            "value": 'User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.',
            "type": 'use and reproduction'
          }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <accessCondition type="use and reproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals.</accessCondition>
        </mods>
      XML
    end
  end

  context 'when it is a license' do
    let(:access) do
      Cocina::Models::DescriptiveAccessMetadata.new(
        "note": [
          {
            "value": 'CC by: CC BY Attribution',
            "type": 'license'
          }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <accessCondition type="license">CC by: CC BY Attribution</accessCondition>
        </mods>
      XML
    end
  end
end

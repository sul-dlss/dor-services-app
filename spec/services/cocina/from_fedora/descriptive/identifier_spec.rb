# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Identifier do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { instance_double(Cocina::FromFedora::Descriptive::DescriptiveBuilder, notifier: notifier) }

  let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with an identifier that is from Standard Identifier Source Codes' do
    let(:xml) do
      <<~XML
        <identifier type="ark">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": 'http://bnf.fr/ark:/13030/tf5p30086k',
          "type": 'ARK',
          "note": [
            {
              "type": 'type',
              "value": 'ark',
              "source": {
                "value": 'Standard Identifier Source Codes'
              }
            }
          ]
        }
      ]
    end
  end

  context 'with an identifier with an unknown MODS type that matches a Cocina type' do
    let(:xml) do
      <<~XML
        <identifier type="oclc">123456789203</identifier>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": '123456789203',
          "type": 'OCLC'
        }
      ]
    end
  end

  context 'with an identifier with an unknown MODS type that does not match a Cocina type' do
    let(:xml) do
      <<~XML
        <identifier type="xyz">123456789203</identifier>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "value": '123456789203',
          "type": 'xyz'
        }
      ]
    end
  end
end

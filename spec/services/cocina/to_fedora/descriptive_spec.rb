# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive do
  subject(:xml) { described_class.transform(descriptive).to_xml }

  context 'when the title is a basic value' do
    let(:descriptive) do
      Cocina::Models::Description.new(
        title: [
          { value: "Gaudy night" }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>Gaudy night</title>
          </titleInfo>
        </mods>
      XML
    end
  end

  context 'when the title has a structured value' do
    let(:descriptive) do
      Cocina::Models::Description.new(
        title: [
          { structuredValue: [{ type: 'nonsorting characters', value: 'The' },
                              { type: 'main title', value: 'journal of stuff' },
                              { type: 'part number', value: 'volume 5' },
                              { type: 'part name', value: 'special issue' },
                              { note: [{ type: 'nonsorting character count', value: '4' }] }] }
        ]
      )
    end

    it 'builds the xml' do
      expect(xml).to be_equivalent_to <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <nonSort>The</nonSort>
            <title>journal of stuff</title>
            <partNumber>volume 5</partNumber>
            <partName>special issue</partName>
          </titleInfo>
        </mods>
      XML
    end
  end
end

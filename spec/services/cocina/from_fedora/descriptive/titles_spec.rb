# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Titles do
  let(:object) { Dor::Item.new }

  describe '.build' do
    subject(:build) { described_class.build(ng_xml) }

    context 'when the object has no title' do
      let(:ng_xml) { Dor::Item.new.descMetadata.ng_xml }

      it 'raises and error' do
        expect { build }.to raise_error Cocina::Mapper::MissingTitle
      end
    end

    context 'when the title has parts' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
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

      it 'is a structured value' do
        expect(build).to eq [
          { structuredValue: [{ type: 'nonsorting characters', value: 'The' },
                              { type: 'main title', value: 'journal of stuff' },
                              { type: 'part number', value: 'volume 5' },
                              { type: 'part name', value: 'special issue' },
                              { note: [{ type: 'nonsorting character count', value: 4 }] }] }
        ]
      end
    end
  end
end

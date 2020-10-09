# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Contributor do
  let(:object) { Dor::Item.new }

  describe '.build' do
    subject(:build) { described_class.build(ng_xml) }

    context 'when the role is missing the authority' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <name valueURI="corporate">
              <namePart>Selective Service System</namePart>
              <role>
                <roleTerm type="code">isb</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end

      it 'raises an error' do
        expect { build }.to raise_error Cocina::Mapper::InvalidDescMetadata, './mods:role/mods:roleTerm[@type="code"] is missing required authority attribute'
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Event do
  subject(:build) { described_class.build(ng_xml) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with a simple dateCreated' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCreated>1980</dateCreated>
        </originInfo>
      XML
    end

    it 'raises an error' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '1980'
            }
          ]
        }
      ]
    end
  end
end

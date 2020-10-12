# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Descriptive do
  subject(:xml) { described_class.transform(descriptive).to_xml }

  context 'when it has an abstract' do
    let(:descriptive) do
      Cocina::Models::Description.new(
        title: [
          { value: 'Gaudy night' }
        ],
        note: [
          {
            value: 'This is an abstract.',
            type: 'summary'
          }
        ],
        form: [
          {
            value: '1:22,000,000',
            type: 'map scale'
          },
          {
            value: 'Conic proj',
            type: 'map projection'
          }
        ],
        subject: [
          {
            value: 'E 72°--E 148°/N 13°--N 18°',
            type: 'map coordinates',
            encoding: {
              value: 'DMS'
            }
          }
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
          <abstract>This is an abstract.</abstract>
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale>1:22,000,000</scale>
              <projection>Conic proj</projection>
            </cartographics>
          </subject>
        </mods>
      XML
    end
  end
end

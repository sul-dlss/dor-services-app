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
        subject: [
          {
            "value": 'Cats',
            "type": 'topic'
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
            <topic>Cats</topic>
          </subject>
        </mods>
      XML
    end
  end
end

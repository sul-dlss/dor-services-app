# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Notes do
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

  context 'with a simple note' do
    let(:xml) do
      <<~XML
        <note>This is a note.</note>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is a note.'
        }

      ]
    end
  end

  context 'with a note with a type' do
    let(:xml) do
      <<~XML
        <note type="preferred citation">This is the preferred citation.</note>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is the preferred citation.',
          "type": 'preferred citation'
        }

      ]
    end
  end

  context 'with a note with a display label' do
    let(:xml) do
      <<~XML
        <note displayLabel="Conservation note">This is a conservation note.</note>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is a conservation note.',
          "displayLabel": 'Conservation note'
        }

      ]
    end
  end

  context 'with an empty note' do
    let(:xml) do
      <<~XML
        <note />
      XML
    end

    it 'omits the note' do
      expect(build).to eq []
    end
  end

  context 'with a single abstract' do
    let(:xml) do
      <<~XML
        <abstract>This is an abstract.</abstract>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is an abstract.',
          "type": 'summary'
        }

      ]
    end
  end

  context 'with a single abstract with a displayLabel' do
    let(:xml) do
      <<~XML
        <abstract displayLabel="Synopsis">This is a synopsis.</abstract>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [

        {
          "value": 'This is a synopsis.',
          "type": 'summary',
          "displayLabel": 'Synopsis'
        }

      ]
    end
  end
end

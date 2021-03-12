# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModsValidator do
  let(:result) { described_class.valid?(Nokogiri.XML(mods)) }

  context 'when valid' do
    let(:mods) do
      <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.7">
          <titleInfo>
            <title>Kayaking the Main Coast</title>
          </titleInfo>
        </mods>
      XML
    end

    it 'returns success' do
      expect(result.success?).to be true
    end
  end

  context 'when invalid' do
    let(:mods) do
      <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.7">
          <frequency>often</frequency>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be true
      expect(result.failure.first).to start_with("2:0: ERROR: Element '{http://www.loc.gov/mods/v3}frequency': This element is not expected.")
    end
  end

  context 'when missing version' do
    let(:mods) do
      <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3">
          <titleInfo>
            <title>Kayaking the Main Coast</title>
          </titleInfo>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be true
      expect(result.failure.first).to start_with('MODS version attribute not found.')
    end
  end

  context 'when unknown version' do
    let(:mods) do
      <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="1.0">
          <titleInfo>
            <title>Kayaking the Main Coast</title>
          </titleInfo>
        </mods>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be true
      expect(result.failure.first).to start_with('Unknown MODS version.')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fedora::RightsValidator do
  let(:result) { described_class.valid?(Nokogiri.XML(ds)) }

  context 'when valid' do
    let(:ds) do
      <<~XML
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <none/>
            </machine>
          </access>
          <copyright>
            <human/>
          </copyright>
          <use>
            <human type="useAndReproduction"/>
          </use>
        </rightsMetadata>
      XML
    end

    it 'returns success' do
      expect(result.success?).to be true
    end
  end

  context 'when invalid' do
    let(:ds) do
      <<~XML
        <rightsMetadata>
        </rightsMetadata>
      XML
    end

    it 'returns failure' do
      expect(result.failure?).to be true
      expect(result.failure.first).to start_with('no_discover_access, no_discover_machine')
    end
  end
end

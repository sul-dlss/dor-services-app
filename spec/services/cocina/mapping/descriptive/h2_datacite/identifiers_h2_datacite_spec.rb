# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for identifier and alternateIdentifier (H2 specific)' do
  # NOTE: Because we haven't set a title in this Cocina::Models::Description, it will not validate against the openapi.
  let(:cocina_description) { Cocina::Models::Description.new(cocina.merge(purl: cocina.fetch(:purl, 'https://purl.stanford.edu/aa666bb1234')), false, false) }
  let(:identifier_attributes) { Cocina::ToDatacite::Identifier.identifier_attributes(cocina_description) }
  let(:alternate_identifier_attributes) { Cocina::ToDatacite::Identifier.alternate_identifier_attributes(cocina_description) }

  describe 'DOI' do
    # DOI: 10.5072/example
    let(:cocina) do
      {
        identifier: [
          {
            value: '10.5072/example',
            type: 'DOI'
          }
        ]
      }
    end

    it 'populates identifier_attributes correctly' do
      expect(identifier_attributes).to eq [
        {
          identifier: '10.5072/example',
          identifierType: 'DOI'
        }
      ]
    end
  end

  describe 'purl' do
    # purl: http://purl.stanford.edu/gz708sf9862
    let(:cocina) do
      {
        purl: 'http://purl.stanford.edu/gz708sf9862'
      }
    end

    it 'populates alternate_identifier_attributes correctly' do
      expect(alternate_identifier_attributes).to eq [
        {
          alternateIdentifier: 'http://purl.stanford.edu/gz708sf9862',
          alternateIdentifierType: 'PURL'
        }
      ]
    end
  end

  ### --------------- specs below added by developers ---------------

  context 'when cocina identifier array has empty hash' do
    let(:cocina) do
      {
        identifier: [
          {
          }
        ]
      }
    end

    it 'identifier_attributes is nil' do
      expect(identifier_attributes).to eq nil
    end
  end

  context 'when cocina identifier is empty array' do
    let(:cocina) do
      {
        identifier: []
      }
    end

    it 'identifier_attributes is nil' do
      expect(identifier_attributes).to eq nil
    end
  end

  context 'when cocina has no identifier' do
    let(:cocina) do
      {
      }
    end

    it 'identifier_attributes is nil' do
      expect(identifier_attributes).to eq nil
    end
  end
end

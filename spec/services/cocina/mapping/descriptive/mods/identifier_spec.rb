# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS identifier <--> cocina mappings' do
  describe 'Identifier with type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier type="isbn">1234 5678 9203</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              value: '1234 5678 9203',
              type: 'ISBN',
              note: [
                {
                  type: 'type',
                  value: 'isbn',
                  uri: 'http://id.loc.gov/vocabulary/identifiers/isbn',
                  source: {
                    value: 'Standard Identifier Schemes',
                    uri: 'http://id.loc.gov/vocabulary/identifiers/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'URI as identifier' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier type="uri">https://www.wikidata.org/wiki/Q146</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              uri: 'https://www.wikidata.org/wiki/Q146',
              note: [
                {
                  type: 'type',
                  value: 'uri',
                  uri: 'http://id.loc.gov/vocabulary/identifiers/uri',
                  source: {
                    value: 'Standard Identifier Schemes',
                    uri: 'http://id.loc.gov/vocabulary/identifiers/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Identifier with display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier displayLabel="Accession number">1980-12345</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              value: '1980-12345',
              displayLabel: 'Accession number'
            }
          ]
        }
      end
    end
  end

  describe 'Invalid identifier' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <identifier type="lccn" invalid="yes">sn 87042262</identifier>
        XML
      end

      let(:cocina) do
        {
          identifier: [
            {
              value: 'sn 87042262',
              type: 'LCCN',
              status: 'invalid',
              note: [
                {
                  type: 'type',
                  value: 'lccn',
                  uri: 'http://id.loc.gov/vocabulary/identifiers/lccn',
                  source: {
                    value: 'Standard Identifier Schemes',
                    uri: 'http://id.loc.gov/vocabulary/identifiers/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end
end

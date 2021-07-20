# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for identifier and alternateIdentifier (H2 specific)' do
  describe 'DOI' do
    # DOI: 10.5072/example
    xit 'not implemented' do
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

      let(:datacite) do
        {
          data: {
            attributes: {
              identifier: '10.5072/example',
              identifierType: 'DOI'
            }
          }
        }
      end
    end
  end

  describe 'purl' do
    # purl: http://purl.stanford.edu/gz708sf9862
    xit 'not implemented' do
      let(:cocina) do
        {
          purl: 'http://purl.stanford.edu/gz708sf9862'
        }
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              alternateIdentifiers: [
                {
                  alternateIdentifier: 'http://purl.stanford.edu/gz708sf9862',
                  alternateIdentifierType: 'PURL'
                }
              ]
            }
          }
        }
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for access (H2 specific)' do
  describe 'Contact email' do
    it_behaves_like 'cocina Datacite mapping' do
      let(:cocina) do
        {
          access: {
            accessContact: [
              {
                value: 'me@stanford.edu',
                type: 'email',
                displayLabel: 'Contact'
              }
            ]
          }
        }
      end

      let(:datacite) do
        # no data generated
        <<~XML
          XML
      end
    end
  end
end

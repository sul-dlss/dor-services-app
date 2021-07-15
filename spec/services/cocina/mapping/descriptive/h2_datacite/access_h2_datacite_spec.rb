# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for access (H2 specific)' do
  describe 'Contact email' do
    xit 'not implemented' do
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
        {}
      end
    end
  end
end

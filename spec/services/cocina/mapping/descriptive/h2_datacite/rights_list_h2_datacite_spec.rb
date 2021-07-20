# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for rightsList (H2 specific)' do
  describe 'License' do
    # User selects Creative Commons Public Domain 1.0 license
    xit 'not implemented' do
      # Top-level access section, not part of description
      let(:cocina) do
        {
          access: {
            license: 'https://creativecommons.org/publicdomain/mark/1.0/'
          }
        }
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              rightsList: [
                {
                  rights: 'https://creativecommons.org/publicdomain/mark/1.0/'
                }
              ]
            }
          }
        }
      end
    end
  end
end

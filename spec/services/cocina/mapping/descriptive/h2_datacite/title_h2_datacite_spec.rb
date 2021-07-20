# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for title (H2 specific)' do
  describe 'Resource title' do
    # User enters title "Tales of a brooding sea star"
    xit 'not implemented' do
      let(:cocina) do
        {
          title: [
            {
              value: 'Tales of a brooding sea star'
            }
          ]
        }
      end

      let(:datacite) do
        {
          data: {
            attributes: {
              titles: [
                {
                  title: 'Tales of a brooding sea star'
                }
              ]
            }
          }
        }
      end
    end
  end
end

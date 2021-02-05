# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for access (H2 specific)' do
  describe 'Contact email' do
    it_behaves_like 'cocina MODS mapping' do
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

      let(:mods) do
        <<~XML
          <note type="contact" displayLabel="Contact">me@stanford.edu</note>
        XML
      end
    end
  end
end

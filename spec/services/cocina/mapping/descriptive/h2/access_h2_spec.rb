# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for access (H2 specific)' do
  describe 'Contact email' do
    xit 'not implemented: email to MODS'

    let(:cocina) do
      {
        access: {
          accessContact: [
            {
              value: 'me@stanford.edu',
              type: 'email',
              displayLabel: 'Contact'
            }
          ],
          digitalRepository: [
            {
              value: 'Stanford Digital Repository'
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

  describe 'Contact email not provided' do
    xit 'no MODS output'

    let(:cocina) do
      {
        access: {
          digitalRepository: [
            {
              value: 'Stanford Digital Repository'
            }
          ]
        }
      }
    end
  end
end

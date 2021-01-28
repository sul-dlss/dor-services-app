# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for access (H2 specific)' do
  describe 'Contact email' do
    xit 'FIXME: get MODS mapping for email (is it part of name ?)'

    # this is clearly wrong
    let(:mods) do
      <<~XML
        <location>
          <physicalLocation type="email" displayLabel="Contact">me@stanford.edu</physicalLocation>
        </location>
      XML
    end

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
  end

  describe 'Contact email not provided' do
    xit 'FIXME: cocina -> MODS ok, but no way to get back'

    let(:mods) { '' }

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

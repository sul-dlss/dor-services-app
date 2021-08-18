# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for description.access (H2 specific)' do
  # NOTE: Because we haven't set a title in this Cocina::Models::Description, it will not validate against the openapi.
  let(:cocina_description) { Cocina::Models::Description.new(cocina, false, false) }
  let(:descriptions_attributes) { Cocina::ToDatacite::Note.descriptions_attributes(cocina_description) }

  describe 'Contact email' do
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

    it 'does not map' do
      expect(descriptions_attributes).to be nil
    end
  end

  ### --------------- specs below added by developers ---------------

  context 'when description.access is empty hash' do
    let(:cocina) do
      {
        access: {}
      }
    end

    it 'does not map' do
      expect(descriptions_attributes).to be nil
    end
  end
end

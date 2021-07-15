# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for adminMetadata (H2 specific)' do
  describe 'New record' do
    let(:create_date) { '2018-10-25' }

    it_behaves_like 'cocina MODS mapping' do
      # Adapted from druid:bc777tp9978.
      let(:cocina) do
        {
          adminMetadata: {
            event: [
              {
                type: 'creation',
                date: [
                  {
                    value: create_date,
                    encoding: {
                      code: 'w3cdtf'
                    }
                  }
                ]
              }
            ],
            note: [
              {
                value: 'Metadata created by user via Stanford self-deposit application',
                type: 'record origin'
              }
            ]
          }
        }
      end

      let(:mods) do
        <<~XML
          <recordInfo>
            <recordOrigin>Metadata created by user via Stanford self-deposit application</recordOrigin>
            <recordCreationDate encoding="w3cdtf">#{create_date}</recordCreationDate>
          </recordInfo>
        XML
      end
    end
  end
end

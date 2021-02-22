# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for adminMetadata (H2 specific)' do
  let(:h2_version) { '1' }

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
                value: "Metadata created by user via Stanford self-deposit application v.#{h2_version}",
                type: 'record origin'
              }
            ]
          }
        }
      end

      let(:mods) do
        <<~XML
          <recordInfo>
            <recordOrigin>Metadata created by user via Stanford self-deposit application v.#{h2_version}</recordOrigin>
            <recordCreationDate encoding="w3cdtf">#{create_date}</recordCreationDate>
          </recordInfo>
        XML
      end
    end
  end

  describe 'Modified record' do
    xit 'not implemented: recordInfo/recordChangeDate as a note when mapping MODS -> cocina'

    let(:create_date) { '2014-04-08' }

    let(:modification_date) { '2014-10-22' }

    it_behaves_like 'cocina MODS mapping' do
      # adapted from jv545yc8727

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
              },
              {
                type: 'modification',
                date: [
                  {
                    value: modification_date,
                    encoding: {
                      code: 'w3cdtf'
                    }
                  }
                ]
              }
            ],
            note: [
              {
                value: "Metadata created by user via Stanford self-deposit application v.#{h2_version}",
                type: 'record origin'
              },
              {
                value: "Metadata modified by user via Stanford self-deposit application v.#{h2_version}",
                type: 'record origin'
              }
            ]
          }
        }
      end

      let(:mods) do
        <<~XML
          <recordInfo>
            <recordOrigin>Metadata created by user via Stanford self-deposit application v.#{h2_version}</recordOrigin>
            <recordOrigin>Metadata modified by user via Stanford self-deposit application v.#{h2_version}</recordOrigin>
            <recordCreationDate encoding="w3cdtf">#{create_date}</recordCreationDate>
            <recordChangeDate encoding="w3cdtf">#{modification_date}</recordChangeDate>
          </recordInfo>
        XML
      end
    end
  end
end

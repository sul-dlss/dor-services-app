# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS physicalDescription <--> cocina mappings' do
  describe 'DataCite resourceTypeGeneral' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <extension displayLabel="datacite">
            <resourceType resourceTypeGeneral="Dataset"/>
          </extension>
        XML
      end

      let(:cocina) do
        {
          form: [
            {
              value: 'Dataset',
              type: 'resource type',
              source: {
                value: 'DataCite resource types'
              }
            }
          ]
        }
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> MODS mappings for relatedItem' do
  describe 'Related citation' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <note type="preferred citation">Stanford University (Stanford, CA.). (2020). May 2020 dataset. Atmospheric Pressure. Professor Maya Aguirre. Department of Earth Sciences, Stanford University.</note>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          "relatedResource": [
            {
              "type": 'related to',
              "note": [
                {
                  "value": 'Stanford University (Stanford, CA.). (2020). May 2020 dataset. Atmospheric Pressure. Professor Maya Aguirre. Department of Earth Sciences, Stanford University.',
                  "type": 'preferred citation'
                }
              ]
            }
          ]
        }
      end
    end

    # type="related to" is optional.
    let(:roundtrip_cocina) do
      {
        "relatedResource": [
          {
            "note": [
              {
                "value": 'Stanford University (Stanford, CA.). (2020). May 2020 dataset. Atmospheric Pressure. Professor Maya Aguirre. Department of Earth Sciences, Stanford University.',
                "type": 'preferred citation'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'Related link' do
    let(:mods) do
      <<~XML
        <relatedItem>
          <titleInfo>
            <title>A paper</title>
          </titleInfo>
          <location>
            <url>https://www.example.com/paper.html</url>
          </location>
        </relatedItem>
      XML
    end

    let(:cocina) do
      {
        "relatedResource": [
          {
            "type": 'related to',
            "title": [
              {
                "value": 'A paper'
              }
            ],
            "access": {
              "url": [
                {
                  "value": 'https://www.example.com/paper.html'
                }
              ]
            }
          }
        ]
      }
    end

    xit 'broken'
  end
end

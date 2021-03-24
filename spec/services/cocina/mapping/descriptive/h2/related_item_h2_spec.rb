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
          relatedResource: [
            {
              note: [
                {
                  value: 'Stanford University (Stanford, CA.). (2020). May 2020 dataset. Atmospheric Pressure. Professor Maya Aguirre. Department of Earth Sciences, Stanford University.',
                  type: 'preferred citation'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Related link with title' do
    it_behaves_like 'cocina MODS mapping' do
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
          relatedResource: [
            {
              title: [
                {
                  value: 'A paper'
                }
              ],
              access: {
                url: [
                  {
                    value: 'https://www.example.com/paper.html'
                  }
                ]
              }
            }
          ]
        }
      end
    end
  end

  describe 'Related link without title' do
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <relatedItem>
            <location>
              <url>https://www.example.com/paper.html</url>
            </location>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              access: {
                url: [
                  {
                    value: 'https://www.example.com/paper.html'
                  }
                ]
              }
            }
          ]
        }
      end
    end
  end
end

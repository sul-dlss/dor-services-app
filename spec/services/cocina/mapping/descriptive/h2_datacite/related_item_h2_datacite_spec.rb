# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for relatedItem' do
  xit 'not implemented' do
    describe 'Related citation' do
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

      let(:datacite) do
        <<~XML
          <relatedItems>
            <relatedItem relatedItemType="Other" relationType="References">
              <titles>
                <title>Stanford University (Stanford, CA.). (2020). May 2020 dataset. Atmospheric Pressure. Professor Maya Aguirre. Department of Earth Sciences, Stanford University.</title>
              </titles>
            </relatedItem>
          </relatedItems>
        XML
      end
    end
  end

  describe 'Related link with title' do
    xit 'not implemented' do
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

      let(:datacite) do
        <<~XML
          <relatedItems>
            <relatedItem relatedItemType="Other" relationType="References">
              <titles>
                <title>A paper</title>
              </titles>
              <relatedItemIdentifier relatedItemIdentifierType="URL">https://www.example.com/paper.html</relatedItemIdentifier>
            </relatedItem>
          </relatedItems>
        XML
      end
    end
  end

  describe 'Related link without title' do
    xit 'not implemented' do
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

      let(:datacite) do
        <<~XML
          <relatedItems>
            <relatedItem relatedItemType="Other" relationType="References">
              <relatedItemIdentifier relatedItemIdentifierType="URL">https://www.example.com/paper.html</relatedItemIdentifier>
            </relatedItem>
          </relatedItems>
        XML
      end
    end
  end
end

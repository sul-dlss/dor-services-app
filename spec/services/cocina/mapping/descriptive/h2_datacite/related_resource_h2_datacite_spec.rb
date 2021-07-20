# frozen_string_literal: true

require 'rails_helper'

# relatedItem attribute new in DataCite schema v. 4.4 and not included in API docs as of 2021-07
RSpec.describe 'Cocina --> DataCite mappings for relatedItem' do
  # Note that this instantiation of Description does NOT validate against OpenAPI due to title validation issues.
  let(:cocina_description) { Cocina::Models::Description.new(cocina, false, false) }
  let(:related_item_attributes) { Cocina::ToDatacite::RelatedResource.related_item_attributes(cocina_description) }

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

    it 'populates related_item_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <relatedItems>
      #       <relatedItem relatedItemType="Other" relationType="References">
      #         <titles>
      #           <title>Stanford University (Stanford, CA.). (2020). May 2020 dataset. yadda yadda</title>
      #         </titles>
      #       </relatedItem>
      #     </relatedItems>
      #   XML
      # end
      expect(related_item_attributes).to eq(
        {
          relatedItemType: 'Other',
          relationType: 'References',
          titles: [
            {
              title: 'Stanford University (Stanford, CA.). (2020). May 2020 dataset. Atmospheric Pressure. Professor Maya Aguirre. Department of Earth Sciences, Stanford University.'
            }
          ]
        }
      )
    end
  end

  describe 'Related link with title' do
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

    xit 'populates related_item_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <relatedItems>
      #       <relatedItem relatedItemType="Other" relationType="References">
      #         <titles>
      #           <title>A paper</title>
      #         </titles>
      #         <relatedItemIdentifier relatedItemIdentifierType="URL">https://www.example.com/paper.html</relatedItemIdentifier>
      #       </relatedItem>
      #     </relatedItems>
      #   XML
      # end
      expect(related_item_attributes).to eq(
        {
          relatedItemType: 'Other',
          relationType: 'References',
          titles: [
            {
              title: 'A paper'
            }
          ],
          relatedItemIdentifier: 'https://www.example.com/paper.html',
          relatedItemIdentifierType: 'URL'
        }
      )
    end
  end

  describe 'Related link without title' do
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

    xit 'populates related_item_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <relatedItems>
      #       <relatedItem relatedItemType="Other" relationType="References">
      #         <relatedItemIdentifier relatedItemIdentifierType="URL">https://www.example.com/paper.html</relatedItemIdentifier>
      #       </relatedItem>
      #     </relatedItems>
      #   XML
      # end
      expect(related_item_attributes).to eq(
        {
          relatedItemType: 'Other',
          relationType: 'References',
          relatedItemIdentifier: 'https://www.example.com/paper.html',
          relatedItemIdentifierType: 'URL'
        }
      )
    end
  end
end

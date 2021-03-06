# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for note' do
  describe 'Abstract' do
    xit 'not implemented' do
      let(:cocina) do
        {
          note: [
            {
              type: 'abstract',
              value: 'My paper is about dolphins.'
            }
          ]
        }
      end

      # let(:datacite_xml) do
      #   <<~XML
      #     <descriptions>
      #       <description descriptionType="Abstract">My paper is about dolphins.</description>
      #     </descriptions>
      #   XML
      # end

      let(:datacite) do
        {
          data: {
            attributes: {
              descriptions: [
                {
                  description: 'My paper is about dolphins.',
                  descriptionType: 'Abstract'
                }
              ]
            }
          }
        }
      end
    end
  end
end

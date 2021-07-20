# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for note' do
  # Note that this instantiation of Description does NOT validate against OpenAPI due to title validation issues.
  let(:cocina_description) { Cocina::Models::Description.new(cocina, false, false) }
  let(:descriptions_attributes) { Cocina::ToDatacite::Note.descriptions_attributes(cocina_description) }

  describe 'Abstract' do
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

    it 'populates descriptions_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <descriptions>
      #       <description descriptionType="Abstract">My paper is about dolphins.</description>
      #     </descriptions>
      #   XML
      # end
      expect(descriptions_attributes).to eq(
        {
          description: 'My paper is about dolphins.',
          descriptionType: 'Abstract'
        }
      )
    end
  end

  ### --------------- specs below added by developers ---------------

  context 'when cocina note array has empty hash' do
    let(:cocina) do
      {
        note: [
          {
          }
        ]
      }
    end

    it 'descriptions_attributes is empty hash' do
      expect(descriptions_attributes).to eq({})
    end
  end

  context 'when cocina note is empty array' do
    let(:cocina) do
      {
        note: []
      }
    end

    it 'descriptions_attributes is empty hash' do
      expect(descriptions_attributes).to eq({})
    end
  end

  context 'when cocina has no note' do
    let(:cocina) do
      {
      }
    end

    it 'descriptions_attributes is empty hash' do
      expect(descriptions_attributes).to eq({})
    end
  end
end

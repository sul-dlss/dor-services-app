# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for title (H2 specific)' do
  # Note that this instantiation of Cocina::Models::Description does NOT validate against OpenAPI due to missing title.
  let(:cocina_description) { Cocina::Models::Description.new(cocina, false, false) }
  let(:title_attributes) { Cocina::ToDatacite::Title.title_attributes(cocina_description) }

  describe 'Resource title' do
    # User enters title "Tales of a brooding sea star"
    let(:cocina) do
      {
        title: [
          {
            value: 'Tales of a brooding sea star'
          }
        ]
      }
    end

    it 'populates title_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <resourceType resourceTypeGeneral="Dataset">Data</resourceType>
      #   XML
      # end
      expect(title_attributes).to eq(
        {
          title: 'Tales of a brooding sea star'
        }
      )
    end
  end

  ### --------------- specs below added by developers ---------------

  context 'when cocina title array has empty hash' do
    let(:cocina) do
      {
        title: [
          {
          }
        ]
      }
    end

    it 'title_attributes is empty hash' do
      expect(title_attributes).to eq({})
    end
  end

  context 'when cocina title is empty array' do
    let(:cocina) do
      {
        title: []
      }
    end

    it 'title_attributes is empty hash' do
      expect(title_attributes).to eq({})
    end
  end

  context 'when cocina has no title' do
    let(:cocina) do
      {
      }
    end

    it 'title_attributes is empty hash' do
      expect(title_attributes).to eq({})
    end
  end
end

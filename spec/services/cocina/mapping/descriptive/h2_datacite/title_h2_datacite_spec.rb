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
      expect(title_attributes).to eq [
        {
          title: 'Tales of a brooding sea star'
        }
      ]
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for title (H2 specific)' do
  let(:druid) { 'druid:bb423sd6663' }
  let(:cocina_object) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::ObjectType.object,
                            version: 1,
                            description: cocina.merge(purl: Purl.for(druid:)),
                            identification: {
                              sourceId: 'sul:8.559351'
                            },
                            access: {},
                            administrative: {
                              hasAdminPolicy: 'druid:pp000pp0000'
                            },
                            structural: {})
  end
  let(:title_attributes) { Cocina::ToDatacite::Title.title_attributes(cocina_object) }

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

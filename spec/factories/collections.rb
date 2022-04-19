# frozen_string_literal: true

FactoryBot.define do
  factory :ar_collection, class: 'Collection' do
    cocina_version { Cocina::Models::VERSION }
    external_identifier { generate(:unique_druid) }
    collection_type { Cocina::Models::ObjectType.collection }
    label { 'Test Collection' }
    version { 1 }
    access do
      { view: 'world' }
    end
    description do
      {
        title: [{ value: 'Test Collection' }],
        purl: "https://purl.stanford.edu/#{external_identifier.delete_prefix('druid:')}"
      }
    end
    sequence(:identification) do |n|
      { sourceId: "googlebooks:c#{n}" }
    end
    administrative do
      { hasAdminPolicy: 'druid:hy787xj5878' }
    end
  end
end

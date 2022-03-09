# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    cocina_version { '0.0.1' }
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
        purl: 'https://purl.stanford.edu/hp308wm0436'
      }
    end
  end

  trait :with_collection_identification do
    identification do
      { sourceId: 'googlebooks:999999' }
    end
  end

  trait :with_administrative do
    administrative do
      { hasAdminPolicy: 'druid:hy787xj5878' }
    end
  end
end

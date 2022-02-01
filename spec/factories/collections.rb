# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    cocina_version { '0.0.1' }
    external_identifier { 'druid:hp308wm0436' }
    collection_type { Cocina::Models::Vocab.collection }
    label { 'Test Collection' }
    version { 1 }
    access do
      { access: 'world' }
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

  trait :with_collection_description do
    description do
      {
        title: [{ value: 'Test Collection' }],
        purl: 'https://purl.stanford.edu/hp308wm0436'
      }
    end
  end
end

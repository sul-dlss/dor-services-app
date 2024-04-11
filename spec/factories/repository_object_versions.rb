# frozen_string_literal: true

FactoryBot.define do
  factory :repository_object_version do
    sequence(:version)
    version_description { 'MyString' }
    cocina_version { 1 }
    content_type { 'MyString' }
    label { 'MyString' }
    access { '' }
    administrative { '' }
    description { '' }
    identification { '' }
    structural { '' }
    geographic { '' }
    created_at { Time.current }
    updated_at { Time.current }
    closed_at { nil }
  end
end

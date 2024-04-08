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
    closed_at { '2024-03-28 09:23:39' }
  end
end

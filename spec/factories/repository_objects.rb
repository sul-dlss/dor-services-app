# frozen_string_literal: true

FactoryBot.define do
  factory :repository_object do
    object_type { 'dro' }
    external_identifier { generate(:unique_druid) }
    source_id { "sul:#{SecureRandom.uuid}" }
    lock { 'MyString' }
  end
end

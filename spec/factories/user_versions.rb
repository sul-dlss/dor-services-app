# frozen_string_literal: true

FactoryBot.define do
  factory :user_version do
    sequence(:version)
    state { 'available' }
    repository_object_version
  end
end

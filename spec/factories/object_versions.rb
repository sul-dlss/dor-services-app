# frozen_string_literal: true

FactoryBot.define do
  factory :object_version do
    druid { generate(:unique_druid) }
    sequence(:version)
    sequence(:description) do |n|
      "The scintillating description for version #{n}"
    end
    created_at { Time.current }
    updated_at { Time.current }
  end

  # NOTE: This trait is meant to be used by the :ar_dro, :ar_collection, and :ar_admin_policy factories
  trait :with_object_versions do
    after(:create) do |object|
      create_list(:object_version, object.version, druid: object.external_identifier) do |object_version, i|
        object_version.update!(version: i + 1) # i is zero-based
      end
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :repository_object do
    object_type { :dro }
    external_identifier { generate(:unique_druid) }
    source_id { "sul:#{SecureRandom.uuid}" }
    lock { 1 }
    created_at { Time.current }
    updated_at { Time.current }
  end

  trait :admin_policy do
    object_type { :admin }
  end

  trait :collection do
    object_type { :collection }
  end

  trait :closed do
    after(:create) do |repo_object, _context|
      repo_object.close_version!
    end
  end

  trait :with_repository_object_version do
    transient do
      repository_object_version { nil }
      version { 1 }
    end
    after(:create) do |repo_object, context|
      repo_object_version = context.repository_object_version ||
                            build(:repository_object_version, :"#{repo_object.object_type}_repository_object_version",
                                  external_identifier: repo_object.external_identifier,
                                  source_id: repo_object.source_id, version: context.version)
      if (existing_repo_object_version = repo_object.versions.find_by(version: repo_object_version.version))
        repo_object.update!(last_closed_version: nil, head_version: nil, opened_version: nil)
        existing_repo_object_version.destroy!
      end
      repo_object_version.repository_object = repo_object
      repo_object_version.save!
      repo_object.update!(head_version: repo_object_version, opened_version: repo_object_version)
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :repository_object_version do
    transient do
      external_identifier { generate(:unique_druid) }
      is_member_of { [] }
      source_id { "sul:#{SecureRandom.uuid}" }
    end
    sequence(:version)
    version_description { 'Best version ever' }
    cocina_version { Cocina::Models::VERSION }
    content_type { Cocina::Models::ObjectType.book }
    label { 'Test DRO' }
    access do
      { view: 'world', download: 'world' }
    end
    administrative do
      { hasAdminPolicy: 'druid:hy787xj5878' }
    end
    description do
      {
        title: [{ value: label }],
        purl: "https://purl.stanford.edu/#{external_identifier.delete_prefix('druid:')}"
      }
    end
    identification do
      { sourceId: source_id }
    end
    structural do
      { contains: [
        {
          type: Cocina::Models::FileSetType.file,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/123-456-789', label: 'Page 1', version: 1,
          structural: {
            contains: [
              {
                type: Cocina::Models::ObjectType.file,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456-789',
                label: '00001.html',
                filename: '00001.html',
                size: 0,
                version: 1,
                hasMimeType: 'text/html',
                use: 'transcription',
                hasMessageDigests: [
                  {
                    type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                  }, {
                    type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                  }
                ],
                access: { view: 'dark' },
                administrative: { publish: false, sdrPreserve: true, shelve: false }
              }
            ]
          }
        }
      ] }.tap do |h|
        h.merge!({ isMemberOf: is_member_of }) if is_member_of.present?
      end
    end
    geographic { nil }
    created_at { Time.current }
    updated_at { Time.current }
    closed_at { nil }
  end

  trait :with_repository_object do
    repository_object { association :repository_object, external_identifier: }

    after(:build) do |repository_object_version, _evaluator|
      repository_object = repository_object_version.repository_object
      # Repository object will already have a version 1, so delete it.
      if repository_object_version.version == 1 && repository_object.versions.present?
        repository_object.update(head_version: nil, opened_version: nil, last_closed_version: nil)
        repository_object.versions.first.destroy!
      end
      repository_object.versions << repository_object_version
      repository_object.head_version = repository_object_version
      if repository_object_version.closed_at.present?
        repository_object.last_closed_version = repository_object_version
      else
        repository_object.opened_version = repository_object_version
      end
      repository_object.save!
    end
  end

  trait :dro_repository_object_version do # rubocop:disable Lint/EmptyBlock
  end

  trait :admin_policy_repository_object_version do
    transient do
      access_template { { view: 'world', download: 'world' } }
    end
    label { 'Test Admin Policy' }
    content_type { Cocina::Models::ObjectType.admin_policy }
    administrative do
      {
        hasAdminPolicy: 'druid:hy787xj5878',
        hasAgreement: 'druid:bb033gt0615',
        accessTemplate: access_template
      }
    end
    access { nil }
    identification { nil }
    structural { nil }
  end

  trait :collection_repository_object_version do
    label { 'Test Collection' }
    content_type { Cocina::Models::ObjectType.collection }
    administrative do
      { hasAdminPolicy: 'druid:hy787xj5878' }
    end
    access do
      { view: 'world' }
    end
    structural { nil }
  end

  trait :with_embargo do
    access do
      {
        view: 'dark',
        download: 'dark',
        embargo: {
          releaseDate: 1.year.from_now.iso8601,
          view: 'world',
          download: 'world'
        }
      }
    end
  end

  trait :with_releasable_embargo do
    access do
      {
        view: 'dark',
        download: 'dark',
        embargo: {
          releaseDate: 1.month.ago.iso8601,
          view: 'world',
          download: 'world'
        }
      }
    end
  end
end

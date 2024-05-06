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
end

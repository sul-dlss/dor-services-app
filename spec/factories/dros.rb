# frozen_string_literal: true

FactoryBot.define do
  factory :ar_dro, class: 'Dro' do
    cocina_version { Cocina::Models::VERSION }
    external_identifier { generate(:unique_druid) }
    content_type { Cocina::Models::ObjectType.book }
    label { 'Test DRO' }
    version { 1 }
    lock { 0 }
    access do
      { view: 'world', download: 'world' }
    end
    administrative do
      { hasAdminPolicy: 'druid:hy787xj5878' }
    end
    description do
      {
        title: [{ value: 'Test DRO' }],
        purl: "https://purl.stanford.edu/#{external_identifier.delete_prefix('druid:')}"
      }
    end
    sequence(:identification) do |n|
      { sourceId: "googlebooks:d#{n}" }
    end
    transient do
      isMemberOf { [] }
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
        h.merge!({ isMemberOf: }) if isMemberOf.present?
      end
    end
  end

  trait :with_geographic do
    geographic do
      {
        iso19139: '<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">...'
      }
    end
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

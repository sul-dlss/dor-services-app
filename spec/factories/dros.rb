# frozen_string_literal: true

FactoryBot.define do
  factory :dro do
    cocina_version { '0.0.1' }
    external_identifier { 'druid:xz456jk0987' }
    content_type { Cocina::Models::Vocab.book }
    label { 'Test DRO' }
    version { 1 }
    access do
      { access: 'world', download: 'world' }
    end
    administrative do
      { hasAdminPolicy: 'druid:hy787xj5878' }
    end
  end

  trait :with_dro_identification do
    identification do
      { sourceId: 'googlebooks:999999' }
    end
  end

  trait :with_dro_description do
    description do
      {
        title: [{ value: 'Test DRO' }],
        purl: 'https://purl.stanford.edu/xz456jk0987'
      }
    end
  end

  trait :with_structural do
    structural do
      { contains: [
        {
          type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
          externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/123-456-789', label: 'Page 1', version: 1,
          structural: {
            contains: [
              {
                type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                externalIdentifier: 'http://cocina.sul.stanford.edu/file/123-456-789',
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
                access: { access: 'dark' },
                administrative: { publish: false, sdrPreserve: true, shelve: false }
              }
            ]
          }
        }
      ] }
    end
  end

  trait :with_geographic do
    geographic do
      {
        iso19139: '<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">...'
      }
    end
  end
end

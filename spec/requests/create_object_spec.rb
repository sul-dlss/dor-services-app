# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create object' do
  let(:access_template) do
    {
      view: 'world',
      download: 'none',
      copyright: 'All rights reserved unless otherwise indicated.',
      useAndReproductionStatement: 'Property rights reside with the repository...'
    }
  end

  let(:admin_policy_id) { 'druid:vs450xr7956' }

  let(:data) { item.to_json }
  let(:druid) { 'druid:gg777gg7777' }
  let(:marc_service) do
    instance_double(Catalog::MarcService, mods:, mods_ng: Nokogiri::XML(mods))
  end
  let(:mods) { nil }

  before do
    allow(SuriService).to receive(:mint_id).and_return(druid)
    allow(Catalog::MarcService).to receive(:new).and_return(marc_service)
    allow(Indexer).to receive(:reindex)
    repository_object_version = build(:repository_object_version, :admin_policy_repository_object_version,
                                      access_template:, external_identifier: admin_policy_id)
    create(:repository_object, :admin_policy, :with_repository_object_version,
           repository_object_version:, external_identifier: admin_policy_id).external_identifier
  end

  context 'when a DRO is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:expected_structural) { {} }
    let(:view) { 'world' }
    let(:expected) do
      build(:dro, id: druid, label: expected_label, title:, type: Cocina::Models::ObjectType.image, admin_policy_id:)
        .new(
          identification: expected_identification,
          structural: expected_structural,
          access: {
            view:,
            download: 'none',
            copyright: 'All rights reserved unless otherwise indicated.',
            useAndReproductionStatement: 'Property rights reside with the repository...'
          }
        )
    end

    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.image}",
          "label":"#{label}","version":1,
          "access":{
            "view":"#{view}",
            "download":"none",
            "copyright":"All rights reserved unless otherwise indicated.",
            "useAndReproductionStatement":"Property rights reside with the repository..."
          },
          "administrative":{"hasAdminPolicy":"#{admin_policy_id}","partOfProject":"Google Books"},
          "description":{"title":[{"value":"#{title}"}]},
          "identification":#{identification.to_json},
          "structural":#{structural.to_json}}
      JSON
    end
    let(:identification) do
      {
        sourceId: 'googlebooks:999999',
        barcode: '36105036289127'
      }
    end
    let(:expected_identification) { identification }

    let(:structural) { {} }

    context 'when the service is disabled' do
      before do
        allow(Settings.enabled_features).to receive(:registration).and_return(false)
      end

      let(:search_result) { matching_result }

      it 'returns a 503 error' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response).to have_http_status :service_unavailable
        expect(response.body).to eq '{"errors":[{"status":"503","title":"Service Unavailable","detail":"Registration is temporarily disabled"}]}' # rubocop:disable Layout/LineLength
      end
    end

    context 'when an object already exists' do
      before do
        create(:repository_object, :with_repository_object_version, source_id: 'googlebooks:999999',
                                                                    external_identifier: 'druid:bc234fg5678')
        # Dro.new(Dro.to_model_hash(build(:dro).new(identification:))).save!
      end

      it 'returns a 409 error' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response).to have_http_status(:conflict)
        json = JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
        expect(json.dig('errors', 0,
                        'detail')).to eq "An object (druid:bc234fg5678) with the source ID 'googlebooks:999999' has already been registered." # rubocop:disable Layout/LineLength
      end
    end

    context 'when folio instance hrid is provided' do
      let(:expected_label) { title } # label derived from catalog data

      let(:identification) do
        {
          sourceId: 'googlebooks:999999',
          catalogLinks: [
            { catalog: 'folio', catalogRecordId: 'a8888', refresh: true }
          ]
        }
      end

      context 'when no object with the source id exists and the save is successful' do
        let(:mods) do
          <<~XML
            <mods xmlns:xlink="http://www.w3.org/1999/xlink"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xmlns="http://www.loc.gov/mods/v3" version="3.3"
                  xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
              <titleInfo>
                <title>#{title}</title>
              </titleInfo>
            </mods>
          XML
        end

        it 'registers the object with the registration service' do
          expect do
            post '/v1/objects',
                 params: data,
                 headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          end.to change(Event, :count).by(1)
          expect(response.body).to equal_cocina_model(expected)
          expect(response).to have_http_status(:created)
          expect(response.location).to eq "/v1/objects/#{druid}"
          expect(Catalog::MarcService).to have_received(:new).with(folio_instance_hrid: 'a8888')
          expect(response.headers['Last-Modified']).to end_with 'GMT'
          expect(response.headers['X-Created-At']).to end_with 'GMT'
          expect(response.headers['ETag']).to match(%r{W/".+"})
        end
      end

      context 'when using MARC and the save is successful' do
        let(:expected) do
          build(:dro, id: druid, label: expected_label, title:, type: Cocina::Models::ObjectType.image,
                      admin_policy_id:)
            .new(
              identification: expected_identification,
              structural: expected_structural,
              access: {
                view:,
                download: 'none',
                copyright: 'All rights reserved unless otherwise indicated.',
                useAndReproductionStatement: 'Property rights reside with the repository...'
              }
            )
        end
        let(:today) { Time.zone.now.strftime('%Y-%m-%d') }

        let(:expected_description) do
          expected.description.new(adminMetadata: { note: [{
                                     value: "Converted from MARC to Cocina #{today}", type: 'record origin'
                                   }] },
                                   note: [{ value: 'by Some Author.',
                                            type: 'statement of responsibility' }])
        end
        let(:label) { 'Here is my title' }
        let(:title) { 'Here is my title' }
        let(:marc) do
          { fields: [
            { '245': {
              ind1: '1',
              ind2: '0',
              subfields: [
                {
                  a: 'Here is my title /'
                },
                {
                  c: 'by Some Author.'
                }
              ]
            } }
          ] }.deep_stringify_keys
        end
        let(:marc_service) do
          instance_double(Catalog::MarcService, marc:)
        end
        let(:request_data) do
          <<~JSON
            {
              "cocinaVersion":"#{Cocina::Models::VERSION}",
              "type":"#{Cocina::Models::ObjectType.image}",
              "label":"#{label}","version":1,
              "access":{
                "view":"#{view}",
                "download":"none",
                "copyright":"All rights reserved unless otherwise indicated.",
                "useAndReproductionStatement":"Property rights reside with the repository..."
              },
              "administrative":{"hasAdminPolicy":"#{admin_policy_id}","partOfProject":"Google Books"},
              "description":{"title":[{"value":"#{title}"}]},
              "identification":#{identification.to_json},
              "structural":#{structural.to_json}}
          JSON
        end

        before do
          allow(Settings.enabled_features).to receive(:use_marc).and_return(true)
        end

        it 'registers the object with the registration service' do
          expect do
            post '/v1/objects',
                 params: request_data,
                 headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          end.to change(Event, :count).by(1)

          expect(response.body).to equal_cocina_model(expected.new(description: expected_description))
          expect(response).to have_http_status(:created)
          expect(response.location).to eq "/v1/objects/#{druid}"
          expect(Catalog::MarcService).to have_received(:new).with(folio_instance_hrid: 'a8888')
          expect(response.headers['Last-Modified']).to end_with 'GMT'
          expect(response.headers['X-Created-At']).to end_with 'GMT'
          expect(response.headers['ETag']).to match(%r{W/".+"})
        end
      end

      context 'when connecting to catalog fails' do
        before do
          allow(marc_service).to receive(:mods).and_raise(Catalog::MarcService::CatalogResponseError)
        end

        it 'draws an error message' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to eq '{"errors":[{"status":"502","title":"Catalog connection error",' \
                                      '"detail":"Unable to read descriptive metadata from the catalog"}]}'
          expect(response).to have_http_status :bad_gateway
        end
      end

      context 'when requesting MARC while connecting to catalog fails' do
        before do
          allow(marc_service).to receive(:marc).and_raise(Catalog::MarcService::CatalogResponseError)
          allow(Settings.enabled_features).to receive(:use_marc).and_return(true)
        end

        it 'draws an error message' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to eq '{"errors":[{"status":"502","title":"Catalog connection error",' \
                                      '"detail":"Unable to read descriptive metadata from the catalog"}]}'
          expect(response).to have_http_status :bad_gateway
        end
      end

      context 'when catalog returns a 404' do
        before do
          allow(marc_service).to receive(:mods).and_raise(Catalog::MarcService::CatalogRecordNotFoundError,
                                                          'unable to find folio instance hrid')
        end

        it 'draws an error message' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to eq '{"errors":[{"status":"400","title":"Record not found in catalog",' \
                                      '"detail":"unable to find folio instance hrid"}]}'
          expect(response).to have_http_status :bad_request
        end
      end

      context 'when other error refreshing MARC' do
        before do
          allow(marc_service).to receive(:mods).and_raise(Catalog::MarcService::MarcServiceError)
        end

        it 'draws an error message' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to match 'Catalog::MarcService::MarcServiceError'
          expect(response).to have_http_status :internal_server_error
        end
      end
    end

    context 'when folio instance hrid is not provided' do
      context 'when no object with the source id exists and the save is successful' do
        it 'registers the object with the registration service' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to equal_cocina_model(expected)
          expect(response).to have_http_status(:created)
          expect(response.location).to eq "/v1/objects/#{druid}"

          item = CocinaObjectStore.find(druid)
          # Metadata persisted correctly.
          expect(item.label).to eq(expected_label)
          expect(item.type).to eq('https://cocina.sul.stanford.edu/models/image')
          expect(item.identification.barcode).to eq('36105036289127')
        end
      end

      context 'when assigning DOI' do
        let(:expected_identification) do
          {
            sourceId: 'googlebooks:999999',
            barcode: '36105036289127',
            doi: '10.25740/gg777gg7777'
          }
        end

        before do
          allow(Settings.datacite).to receive(:prefix).and_return('10.25740')
        end

        it 'registers the object with a DOI' do
          post '/v1/objects?assign_doi=true',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to equal_cocina_model(expected)
          expect(response).to have_http_status(:created)

          item = CocinaObjectStore.find(druid)
          # Metadata persisted correctly.
          expect(item.identification.doi).to eq('10.25740/gg777gg7777')
        end
      end

      context 'when assign_doi is false' do
        let(:expected_identification) do
          {
            sourceId: 'googlebooks:999999',
            barcode: '36105036289127'
          }
        end

        it 'registers the object without a DOI' do
          post '/v1/objects?assign_doi=false',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(:created)
          expect(response.body).to equal_cocina_model(expected)
        end
      end
    end

    context 'when files are provided' do
      let(:file1) do
        {
          'version' => 1,
          'type' => Cocina::Models::ObjectType.file,
          'filename' => '00001.html',
          'label' => '00001.html',
          'hasMimeType' => 'text/html',
          'languageTag' => 'lou-US',
          'use' => 'transcription',
          'administrative' => {
            'publish' => false,
            'sdrPreserve' => true,
            'shelve' => false
          },
          'access' => {
            'view' => 'dark'
          },
          'hasMessageDigests' => [
            {
              'type' => 'sha1',
              'digest' => 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
            },
            {
              'type' => 'md5',
              'digest' => 'e6d52da47a5ade91ae31227b978fb023'
            }
          ]
        }
      end

      let(:file2) do
        {
          'version' => 1,
          'type' => Cocina::Models::ObjectType.file,
          'filename' => '00001.jp2',
          'label' => '00001.jp2',
          'hasMimeType' => 'image/jp2',
          'administrative' => {
            'publish' => false,
            'sdrPreserve' => true,
            'shelve' => false
          },
          'access' => {
            'view' => 'dark',
            'download' => 'none'
          },
          'hasMessageDigests' => []
        }
      end

      let(:file3) do
        {
          'version' => 1,
          'type' => Cocina::Models::ObjectType.file,
          'filename' => '00002.html',
          'label' => '00002.html',
          'hasMimeType' => 'text/html',
          'administrative' => {
            'publish' => false,
            'sdrPreserve' => true,
            'shelve' => false
          },
          'access' => {
            'view' => 'dark'
          },
          'hasMessageDigests' => []
        }
      end

      let(:file4) do
        {
          'version' => 1,
          'type' => Cocina::Models::ObjectType.file,
          'filename' => '00002.jp2',
          'label' => '00002.jp2',
          'hasMimeType' => 'image/jp2',
          'administrative' => {
            'publish' => false,
            'sdrPreserve' => true,
            'shelve' => false
          },
          'access' => {
            'view' => 'dark',
            'download' => 'none'
          },
          'hasMessageDigests' => []
        }
      end

      let(:filesets) do
        [
          {
            'version' => 1,
            'type' => Cocina::Models::FileSetType.file,
            'label' => 'Page 1',
            'structural' => { 'contains' => [file1, file2] }
          },
          {
            'version' => 1,
            'type' => Cocina::Models::FileSetType.file,
            'label' => 'Page 2',
            'structural' => { 'contains' => [file3, file4] }
          }
        ]
      end

      let(:structural) { { contains: filesets } }

      context 'when identifiers are provided' do
        let(:expected_structural) do
          { contains: [
            {
              type: Cocina::Models::FileSetType.file,
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777-123-456-789',
              label: 'Page 1',
              version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'druid:123',
                    label: '00001.html',
                    filename: '00001.html',
                    version: 1,
                    hasMimeType: 'text/html',
                    languageTag: 'lou-US',
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
                  }, {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456',
                    label: '00001.jp2',
                    filename: '00001.jp2',
                    version: 1,
                    hasMimeType: 'image/jp2', hasMessageDigests: [],
                    access: { view: 'dark', download: 'none' },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }
                ]
              }
            }, {
              type: Cocina::Models::FileSetType.file,
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777-123-456-789',
              label: 'Page 2', version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'druid:456',
                    label: '00002.html', filename: '00002.html',
                    version: 1, hasMimeType: 'text/html',
                    hasMessageDigests: [],
                    access: { view: 'dark' },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }, {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/987-654',
                    label: '00002.jp2',
                    filename: '00002.jp2',
                    version: 1,
                    hasMimeType: 'image/jp2',
                    hasMessageDigests: [],
                    access: { view: 'dark', download: 'none' },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }
                ]
              }
            }
          ] }
        end

        let(:filesets) do
          [
            {
              'version' => 1,
              'type' => Cocina::Models::FileSetType.file,
              'label' => 'Page 1',
              'structural' => { 'contains' => [
                file1.merge(externalIdentifier: 'druid:123'),
                file2.merge(externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456')
              ] }
            },
            {
              'version' => 1,
              'type' => Cocina::Models::FileSetType.file,
              'label' => 'Page 2',
              'structural' => { 'contains' => [
                file3.merge(externalIdentifier: 'druid:456'),
                file4.merge(externalIdentifier: 'https://cocina.sul.stanford.edu/file/987-654')
              ] }
            }
          ]
        end

        before do
          # This gives every file set the same UUID. In reality, they would be unique.
          allow(SecureRandom).to receive(:uuid).and_return('123-456-789')
          allow(Honeybadger).to receive(:notify)
        end

        it 'creates structure' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(:created)
          expect(response.body).to equal_cocina_model(expected)
          expect(response.location).to eq "/v1/objects/#{druid}"
          expect(Honeybadger).to have_received(:notify)
            .with('File ID is not in the expected format. It should begin with https://cocina.sul.stanford.edu',
                  context: { file_id: String, external_identifier: 'druid:gg777gg7777' }).twice

          item = CocinaObjectStore.find(druid)
          # Metadata persisted correctly.
          expect(item.structural.contains.map { |fs| fs.structural.contains.size }).to eq [2, 2]
        end
      end

      context 'when access match' do
        before do
          # This gives every file and file set the same UUID. In reality, they would be unique.
          allow(SecureRandom).to receive(:uuid).and_return('123-456-789')
        end

        let(:expected_structural) do
          { contains: [
            {
              type: Cocina::Models::FileSetType.file,
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777-123-456-789',
              label: 'Page 1', version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777-123-456-789/00001.html',
                    label: '00001.html',
                    filename: '00001.html',
                    version: 1,
                    hasMimeType: 'text/html',
                    languageTag: 'lou-US',
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
                  }, {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777-123-456-789/00001.jp2',
                    label: '00001.jp2',
                    filename: '00001.jp2',
                    version: 1,
                    hasMimeType: 'image/jp2', hasMessageDigests: [],
                    access: { view: 'dark', download: 'none' },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }
                ]
              }
            }, {
              type: Cocina::Models::FileSetType.file,
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777-123-456-789',
              label: 'Page 2', version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777-123-456-789/00002.html',
                    label: '00002.html', filename: '00002.html',
                    version: 1, hasMimeType: 'text/html',
                    hasMessageDigests: [],
                    access: { view: 'dark' },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }, {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777-123-456-789/00002.jp2',
                    label: '00002.jp2',
                    filename: '00002.jp2',
                    version: 1,
                    hasMimeType: 'image/jp2',
                    hasMessageDigests: [],
                    access: { view: 'dark', download: 'none' },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }
                ]
              }
            }
          ] }
        end

        it 'creates contentMetadata' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to equal_cocina_model(expected)
          expect(response).to have_http_status(:created)
          expect(response.location).to eq "/v1/objects/#{druid}"

          item = CocinaObjectStore.find(druid)
          # Metadata persisted correctly.
          expect(item.structural.contains.map { |fs| fs.structural.contains.size }).to eq [2, 2]
        end
      end

      context 'when access mismatch' do
        let(:view) { 'dark' }
        let(:access_mismatch_data) do
          JSON
            .parse(data)
            .tap do |cocina_hash|
              cocina_hash['structural']['contains'].map do |fileset|
                fileset['structural']['contains'].map do |file|
                  file['access']['view'] = 'world'
                  file['access']['download'] = 'world'
                end
              end
          end
            .to_json
        end

        it 'returns 400' do
          post '/v1/objects',
               params: access_mismatch_data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response).to have_http_status :bad_request
          expect(response.body).to eq '{"errors":[' \
                                      '{"status":"400","title":"Bad Request",' \
                                      '"detail":"Not all files have dark access and/or are unshelved when object ' \
                                      'access is dark: ' \
                                      '[\\"00001.html\\", \\"00001.jp2\\", \\"00002.html\\", \\"00002.jp2\\"]"}]}'
        end
      end
    end

    context 'when it is a member of a collection' do
      let(:structural) { { isMemberOf: [collection_id] } }
      let(:expected_structural) { structural }
      let(:collection_id) do
        create(:repository_object, :collection, :with_repository_object_version).external_identifier
      end

      it 'creates collection relationship' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(response).to have_http_status(:created)
        expect(response.location).to eq "/v1/objects/#{druid}"

        item = CocinaObjectStore.find(druid)
        # Metadata persisted correctly.
        expect(item.structural.isMemberOf).to eq [collection_id]
      end
    end

    context 'when no access is provided' do
      let(:data) do
        <<~JSON
          {#{' '}
            "cocinaVersion":"#{Cocina::Models::VERSION}",
            "type":"#{Cocina::Models::ObjectType.image}",
            "label":"#{label}","version":1,
            "administrative":{"hasAdminPolicy":"#{admin_policy_id}","partOfProject":"Google Books"},
            "description":{"title":[{"value":"#{title}"}]},
            "identification":#{identification.to_json},
            "structural":#{structural.to_json}}
        JSON
      end

      it 'has default access' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

        expect(response.body).to equal_cocina_model(expected)
        expect(response).to have_http_status(:created)
        expect(response.location).to eq "/v1/objects/#{druid}"

        item = CocinaObjectStore.find(druid)
        # Metadata persisted correctly.
        expect(item.access.view).to eq 'world'
        expect(item.access.download).to eq 'none'
      end
    end
  end

  context 'when a book is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:expected) do
      build(:dro, id: druid, title:, label: expected_label, admin_policy_id:,
                  type: Cocina::Models::ObjectType.book).new(
                    identification: { sourceId: 'googlebooks:999999' },
                    structural: {
                      hasMemberOrders: [
                        { viewingDirection: 'right-to-left' }
                      ]
                    },
                    access: {
                      view: 'world',
                      download: 'world'
                    }
                  )
    end
    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"#{label}","version":1,"access":{"view":"world","download":"world"},
          "administrative":{"hasAdminPolicy":"#{admin_policy_id}"},
          "description":{"title":[{"value":"#{title}"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end
    let(:access_template) do
      {
        view: 'world',
        download: 'world'
      }
    end

    it 'registers the book and sets the viewing direction' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response).to have_http_status(:created)
      expect(response.location).to eq "/v1/objects/#{druid}"
    end
  end

  context 'when an APO is provided' do
    let(:expected) do
      Cocina::Models::AdminPolicy.new(type: Cocina::Models::ObjectType.admin_policy,
                                      label: 'This is my label',
                                      version: 1,
                                      description: {
                                        title: [{ value: 'This is my title' }],
                                        purl: 'https://purl.stanford.edu/gg777gg7777'
                                      },
                                      administrative: {
                                        accessTemplate: {
                                          view: 'location-based',
                                          download: 'location-based',
                                          location: 'ars',
                                          copyright: 'My copyright statement',
                                          license: 'https://opendatacommons.org/licenses/by/1-0/',
                                          useAndReproductionStatement: 'Whatever makes you happy'
                                        },
                                        hasAdminPolicy: admin_policy_id,
                                        disseminationWorkflow: 'assemblyWF',
                                        registrationWorkflow: %w[goobiWF registrationWF],
                                        collectionsForRegistration: ['druid:gg888df4567', 'druid:bb888gg4444'],
                                        roles: [
                                          {
                                            name: 'dor-apo-manager',
                                            members: [
                                              {
                                                type: 'workgroup',
                                                identifier: 'sdr:psm-staff'
                                              }
                                            ]
                                          }
                                        ],
                                        hasAgreement: 'druid:bc753qt7345'
                                      },
                                      externalIdentifier: druid)
    end

    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.admin_policy}",
          "label":"This is my label","version":1,
          "administrative":{
            "accessTemplate":{
              "view":"location-based",
              "download":"location-based",
              "location":"ars",
              "copyright":"My copyright statement",
              "license":"https://opendatacommons.org/licenses/by/1-0/",
              "useAndReproductionStatement":"Whatever makes you happy"
            },
            "disseminationWorkflow":"assemblyWF",
            "registrationWorkflow":["goobiWF","registrationWF"],
            "collectionsForRegistration":["druid:gg888df4567","druid:bb888gg4444"],
            "hasAdminPolicy":"#{admin_policy_id}",
            "hasAgreement":"druid:bc753qt7345",
            "roles":[{"name":"dor-apo-manager","members":[{"type":"workgroup","identifier":"sdr:psm-staff"}]}]
          },
          "description":{"title":[{"value":"This is my title"}]}}
      JSON
    end

    context 'when the request is successful' do
      it 'registers the object with the registration service' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(response).to have_http_status(:created)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end

    context 'when it belongs to the Ur-AdminPolicy and create_ur_admin_policy is enabled' do
      before do
        allow(Settings.enabled_features).to receive(:create_ur_admin_policy).and_return(true)
        allow(Settings.ur_admin_policy).to receive(:druid).and_return(admin_policy_id)
        allow(CocinaObjectStore).to receive(:exists?).and_return(false)
        allow(UrAdminPolicyFactory).to receive(:create)
      end

      it 'creates the Ur-AdminPolicy' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(UrAdminPolicyFactory).to have_received(:create)

        expect(response).to have_http_status(:created)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end
  end

  context 'when an embargo is provided' do
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.book,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ value: 'This is my title' }],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
                              },
                              administrative: {
                                hasAdminPolicy: admin_policy_id
                              },
                              identification: { sourceId: 'googlebooks:999999' },
                              externalIdentifier: 'druid:gg777gg7777',
                              structural: {
                                hasMemberOrders: [
                                  { viewingDirection: 'right-to-left' }
                                ]
                              },
                              access: {
                                view: 'stanford',
                                download: 'none',
                                controlledDigitalLending: false,
                                embargo: { view: 'world', download: 'world',
                                           releaseDate: '2020-02-29T07:00:00.000+00:00' }
                              })
    end
    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"This is my label","version":1,"access":{"view":"stanford","download":"none","controlledDigitalLending":false,
          "embargo":{"view":"world","download":"world","releaseDate":"2020-02-29T07:00:00.000+00:00"}},
          "administrative":{"hasAdminPolicy":"#{admin_policy_id}"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end
    let(:access_template) do
      {
        view: 'stanford',
        download: 'none',
        controlledDigitalLending: false
      }
    end

    it 'registers the book and sets the rights' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response).to have_http_status(:created)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
    end
  end

  context 'when location access is specified' do
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.book,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ value: 'This is my title' }],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
                              },
                              administrative: {
                                hasAdminPolicy: admin_policy_id
                              },
                              identification: { sourceId: 'googlebooks:999999' },
                              externalIdentifier: 'druid:gg777gg7777',
                              structural: {
                                hasMemberOrders: [
                                  { viewingDirection: 'right-to-left' }
                                ]
                              },
                              access: {
                                view: 'location-based',
                                download: 'location-based',
                                location: 'm&m'
                              })
    end
    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"This is my label","version":1,
          "access":{"view":"location-based","download":"location-based","location":"m&m"},
          "administrative":{"hasAdminPolicy":"#{admin_policy_id}"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end
    let(:access_template) do
      {
        view: 'location-based',
        download: 'location-based',
        location: 'm&m'
      }
    end

    it 'registers the book and sets the rights' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response).to have_http_status(:created)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
    end
  end

  context 'when no-download access is specified' do
    let(:expected) do
      build(:dro, id: 'druid:gg777gg7777', label: 'This is my label', title: 'This is my title',
                  type: Cocina::Models::ObjectType.book, admin_policy_id:).new(
                    structural: {
                      hasMemberOrders: [
                        { viewingDirection: 'right-to-left' }
                      ]
                    },
                    access: {
                      view: 'world',
                      download: 'none'
                    },
                    identification: { sourceId: 'googlebooks:999999' }
                  )
    end
    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"This is my label","version":1,
          "access":{"view":"world","download":"none"},
          "administrative":{"hasAdminPolicy":"#{admin_policy_id}"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end
    let(:access_template) do
      {
        view: 'world',
        download: 'none'
      }
    end

    it 'registers the book and sets the rights' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response.body).to equal_cocina_model(expected)
      expect(response).to have_http_status(:created)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
    end
  end

  context 'when no description is provided (registration use case)' do
    context 'when structural is provided' do
      let(:expected) do
        build(:dro, id: 'druid:gg777gg7777', admin_policy_id:, label: 'This is my label',
                    title: 'This is my label').new(
                      identification: { sourceId: 'googlebooks:999999' }
                    )
      end
      let(:data) do
        <<~JSON
          {#{' '}
            "cocinaVersion":"#{Cocina::Models::VERSION}",
            "type":"#{Cocina::Models::ObjectType.object}",
            "label":"This is my label","version":1,"access":{},
            "administrative":{"hasAdminPolicy":"#{admin_policy_id}"},
            "identification":{"sourceId":"googlebooks:999999"},
            "structural":{}}
        JSON
      end
      let(:access_template) do
        {
          view: 'dark',
          download: 'none'
        }
      end

      it 'registers the object' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(response).to have_http_status(:created)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end

    context 'when structural is not provided' do
      let(:expected) do
        build(:dro, id: 'druid:gg777gg7777', label: 'This is my label', title: 'This is my label',
                    admin_policy_id:).new(
                      identification: { sourceId: 'googlebooks:999999' }
                    )
      end
      let(:data) do
        <<~JSON
          {#{' '}
            "cocinaVersion":"#{Cocina::Models::VERSION}",
            "type":"#{Cocina::Models::ObjectType.object}",
            "label":"This is my label","version":1,"access":{},
            "administrative":{"hasAdminPolicy":"#{admin_policy_id}"},
            "identification":{"sourceId":"googlebooks:999999"},
            "structural":{}
          }
        JSON
      end
      let(:access_template) do
        {
          view: 'dark',
          download: 'none'
        }
      end

      it 'registers the object' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(response).to have_http_status(:created)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end

    context 'when access is not provided' do
      let(:expected) do
        build(:dro, id: 'druid:gg777gg7777', label: 'This is my label', title: 'This is my label',
                    admin_policy_id:).new(
                      identification: { sourceId: 'googlebooks:999999' }
                    )
      end

      let(:data) do
        <<~JSON
          {#{' '}
            "cocinaVersion":"#{Cocina::Models::VERSION}",
            "type":"#{Cocina::Models::ObjectType.object}",
            "label":"This is my label","version":1,
            "administrative":{"hasAdminPolicy":"#{admin_policy_id}"},
            "access":{},
            "identification":{"sourceId":"googlebooks:999999"},
            "structural":{}}
        JSON
      end
      let(:access_template) do
        {
          view: 'dark',
          download: 'none'
        }
      end

      it 'inherits access, copyright and use statement from the admin policy' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(response).to have_http_status(:created)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end
  end
end

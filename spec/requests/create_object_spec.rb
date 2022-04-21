# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create object' do
  let(:apo) do
    Cocina::Models::AdminPolicy.new({
                                      cocinaVersion: Cocina::Models::VERSION,
                                      externalIdentifier: 'druid:dd999df4567',
                                      type: Cocina::Models::ObjectType.admin_policy,
                                      label: 'Test Admin Policy',
                                      version: 1,
                                      administrative: {
                                        hasAdminPolicy: 'druid:hy787xj5878',
                                        hasAgreement: 'druid:bb033gt0615',
                                        accessTemplate: default_access
                                      }
                                    })
  end
  let(:default_access) do
    {
      view: 'world',
      download: 'none',
      copyright: 'All rights reserved unless otherwise indicated.',
      useAndReproductionStatement: 'Property rights reside with the repository...'
    }
  end
  let(:data) { item.to_json }
  let(:druid) { 'druid:gg777gg7777' }
  let(:matching_result) { { 'response' => { 'numFound' => 1, 'docs' => [{ 'id' => 'druid:abc123' }] } } }
  let(:no_result) { { 'response' => { 'numFound' => 0, 'docs' => [] } } }
  let(:search_result) { no_result }

  before do
    allow(SuriService).to receive(:mint_id).and_return(druid)
    allow_any_instance_of(CocinaObjectStore).to receive(:find).with('druid:dd999df4567').and_return(apo)
    allow(Cocina::ActiveFedoraPersister).to receive(:store)
    stub_request(:put, 'https://dor-indexing-app.example.edu/dor/reindex_from_cocina')
    allow(SolrService).to receive(:get).and_return(search_result)
  end

  context 'when a DRO is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:expected_structural) { {} }
    let(:view) { 'world' }
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.image,
                              label: expected_label,
                              version: 1,
                              access: {
                                view: view,
                                download: 'none',
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: {
                                title: [{ value: title }],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567'
                              },
                              identification: expected_identification,
                              externalIdentifier: druid,
                              structural: expected_structural)
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
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
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
        expect(response.status).to eq 503
        expect(response.body).to eq '{"errors":[{"status":"503","title":"Service Unavailable","detail":"Registration is temporarily disabled"}]}'
      end
    end

    context 'when an object already exists' do
      let(:search_result) { matching_result }

      it 'returns a 409 error' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response).to have_http_status(:conflict)
        json = JSON.parse(response.body)
        expect(json.dig('errors', 0, 'detail')).to eq "An object (druid:abc123) with the source ID 'googlebooks:999999' has already been registered."
      end
    end

    context 'when catkey is provided' do
      let(:expected_label) { title } # label derived from catalog data

      let(:identification) do
        {
          sourceId: 'googlebooks:999999',
          catalogLinks: [
            { catalog: 'symphony', catalogRecordId: '8888', refresh: true }
          ]
        }
      end

      context 'when no object with the source id exists and the save is successful' do
        let(:mods_from_symphony) do
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

        before do
          allow(ModsService).to receive(:fetch).and_return(mods_from_symphony)
        end

        it 'registers the object with the registration service and immediately indexes' do
          expect do
            post '/v1/objects',
                 params: data,
                 headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          end.to change(Event, :count).by(1)
          expect(response.body).to equal_cocina_model(expected)
          expect(response.status).to eq(201)
          expect(response.location).to eq "/v1/objects/#{druid}"
          expect(ModsService).to have_received(:fetch).with('catkey:8888')
          expect(a_request(:put, 'https://dor-indexing-app.example.edu/dor/reindex_from_cocina').with do |req|
                   parsed_body = JSON.parse(req.body).deep_symbolize_keys
                   expect(parsed_body[:cocina_object]).to eq(expected.to_h)
                 end).to have_been_made
          expect(response.headers['Last-Modified']).to end_with 'GMT'
          expect(response.headers['X-Created-At']).to end_with 'GMT'
          expect(response.headers['ETag']).to match(%r{W/".+"})
        end
      end

      context 'when connecting to symphony fails' do
        before do
          allow(ModsService).to receive(:fetch).and_raise(SymphonyReader::ResponseError)
        end

        it 'draws an error message' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to eq '{"errors":[{"status":"502","title":"Catalog connection error",' \
                                      '"detail":"Unable to read descriptive metadata from the catalog"}]}'
          expect(response.status).to eq 502
        end
      end

      context 'when symphony returns a 404' do
        before do
          allow(ModsService).to receive(:fetch).and_raise(SymphonyReader::NotFound, 'unable to find catkey')
        end

        it 'draws an error message' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to eq '{"errors":[{"status":"400","title":"Catkey not found in Symphony",' \
                                      '"detail":"unable to find catkey"}]}'
          expect(response.status).to eq 400
        end
      end
    end

    context 'when catkey is not provided' do
      context 'when no object with the source id exists and the save is successful' do
        let(:item) do
          Dor::Item.new(pid: druid,
                        admin_policy_object_id: 'druid:dd999df4567',
                        source_id: 'googlebooks:999999',
                        label: 'This is my label')
        end

        before do
          allow(Dor::Item).to receive(:new).and_return(item)
          allow(item).to receive(:collections).and_return([])
          allow(item).to receive(:save!)
        end

        it 'registers the object with the registration service and immediately indexes' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(a_request(:put, 'https://dor-indexing-app.example.edu/dor/reindex_from_cocina').with do |req|
                   parsed_body = JSON.parse(req.body).deep_symbolize_keys
                   expect(parsed_body[:cocina_object]).to eq(expected.to_h)
                 end).to have_been_made
          expect(response.body).to equal_cocina_model(expected)
          expect(response.status).to eq(201)
          expect(response.location).to eq "/v1/objects/#{druid}"

          # Identity metadata set correctly.
          expect(item.objectId).to eq(druid)
          expect(item.objectCreator.first).to eq('DOR')
          expect(item.objectLabel.first).to eq(expected_label)
          expect(item.objectType.first).to eq('item')
          expect(item.identityMetadata.barcode).to eq('36105036289127')
        end
      end

      # rubocop:disable Layout/LineLength
      context 'when a really long title' do
        let(:item) do
          Dor::Item.new(pid: druid,
                        admin_policy_object_id: 'druid:dd999df4567',
                        source_id: 'googlebooks:999999',
                        label: truncated_label)
        end

        let(:label) { 'Hearings before the Subcommittee on Elementary, Secondary, and Vocational Education of the Committee on Education and Labor, House of Representatives, Ninety-fifth Congress, first session, on H.R. 15, to extend for five years certain elementary, secondary, and other education programs ....' }
        let(:truncated_label) { 'Hearings before the Subcommittee on Elementary, Secondary, and Vocational Education of the Committee on Education and Labor, House of Representatives, Ninety-fifth Congress, first session, on H.R. 15, to extend for five years certain elementary, secondar' }

        before do
          allow(Dor::Item).to receive(:new).and_return(item)
          allow(item).to receive(:collections).and_return([])
          allow(item).to receive(:save!)
        end

        it 'truncates the title' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(a_request(:put, 'https://dor-indexing-app.example.edu/dor/reindex_from_cocina').with do |req|
                   parsed_body = JSON.parse(req.body).deep_symbolize_keys
                   expect(parsed_body[:cocina_object]).to eq(expected.to_h)
                 end).to have_been_made
          expect(response.body).to equal_cocina_model(expected)
          expect(response.status).to eq(201)
          expect(response.location).to eq "/v1/objects/#{druid}"

          expect(Dor::Item).to have_received(:new).with(pid: druid,
                                                        admin_policy_object_id: 'druid:dd999df4567',
                                                        source_id: 'googlebooks:999999',
                                                        collection_ids: [],
                                                        catkey: nil)

          # Identity metadata set correctly.
          expect(item.objectLabel.first).to eq(expected_label)
          expect(item.objectType.first).to eq('item')
        end
      end
      # rubocop:enable Layout/LineLength

      context 'when descriptive roundtrip validation fails' do
        let(:changed_description) do
          {
            title: [{ value: 'changed title' }],
            purl: 'https://purl.stanford.edu/gg777gg7777'
          }
        end

        before do
          allow(Honeybadger).to receive(:notify)
          allow(Cocina::FromFedora::Descriptive).to receive(:props).and_return(changed_description)
        end

        it 'returns error' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(Honeybadger).to have_received(:notify)
        end
      end

      context 'when assigning DOI' do
        let(:item) do
          Dor::Item.new(pid: druid,
                        admin_policy_object_id: 'druid:dd999df4567',
                        source_id: 'googlebooks:999999',
                        label: 'This is my label')
        end

        let(:expected_identification) do
          {
            sourceId: 'googlebooks:999999',
            barcode: '36105036289127',
            doi: '10.25740/gg777gg7777'
          }
        end

        before do
          allow(Dor::Item).to receive(:new).and_return(item)
          allow(item).to receive(:collections).and_return([])
          allow(item).to receive(:save!)
          allow(Settings.datacite).to receive(:prefix).and_return('10.25740')
        end

        it 'registers the object with a DOI' do
          post '/v1/objects?assign_doi=true',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to equal_cocina_model(expected)
          expect(response.status).to eq(201)

          # Identity metadata set correctly.
          expect(item.identityMetadata.ng_xml.at('doi').text).to eq('10.25740/gg777gg7777')
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

      let(:item) do
        Dor::Item.new(pid: druid,
                      admin_policy_object_id: 'druid:dd999df4567',
                      source_id: 'googlebooks:999999',
                      label: 'This is my label').tap do |i|
          i.rightsMetadata.copyright = 'All rights reserved unless otherwise indicated.'
          i.rightsMetadata.use_statement = 'Property rights reside with the repository...'
        end
      end

      before do
        allow(Dor::Item).to receive(:new).and_return(item)
        allow(item).to receive(:collections).and_return([])
        allow(item).to receive(:save!)
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
              externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777-123-456-789', label: 'Page 1', version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777-123-456-789/00001.html',
                    label: '00001.html',
                    filename: '00001.html',
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
          expect(Dor::Item).to have_received(:new)
            .with(pid: druid,
                  admin_policy_object_id: 'druid:dd999df4567',
                  source_id: 'googlebooks:999999',
                  collection_ids: [],
                  catkey: nil)
          expect(response.body).to equal_cocina_model(expected)
          expect(response.status).to eq(201)
          expect(item.contentMetadata.resource.file.count).to eq 4
          expect(response.location).to eq "/v1/objects/#{druid}"
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
          expect(response.status).to eq 400
          expect(response.body).to eq '{"errors":[' \
                                      '{"status":"400","title":"Bad Request",' \
                                      '"detail":"Not all files have dark access and/or are unshelved when object access is dark: ' \
                                      '[\\"00001.html\\", \\"00001.jp2\\", \\"00002.html\\", \\"00002.jp2\\"]"}]}'
        end
      end
    end

    context 'when it is a member of a collection' do
      let(:structural) { { isMemberOf: ['druid:xx888xx7777'] } }
      let(:expected_structural) { structural }

      let(:item) do
        Dor::Item.new(pid: druid,
                      admin_policy_object_id: 'druid:dd999df4567',
                      source_id: 'googlebooks:999999',
                      label: 'This is my label').tap do |i|
          i.rightsMetadata.copyright = 'All rights reserved unless otherwise indicated.'
          i.rightsMetadata.use_statement = 'Property rights reside with the repository...'
        end
      end

      let(:dor_collection) { Dor::Collection.new(pid: 'druid:xx888xx7777') }
      let(:collection) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:xx888xx7777',
                                       type: Cocina::Models::ObjectType.collection,
                                       label: 'Collection of new maps of Africa',
                                       description: {
                                         title: [{ value: 'Collection of new maps of Africa' }],
                                         purl: 'https://purl.stanford.edu/xx888xx7777'
                                       },
                                       version: 1,
                                       cocinaVersion: Cocina::Models::VERSION,
                                       access: {},
                                       administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                                       identification: { sourceId: 'sul:123' })
      end

      before do
        # Allows the CollectionExistenceValidator to find the collection:
        allow_any_instance_of(CocinaObjectStore).to receive(:find).with('druid:xx888xx7777').and_return(collection)

        allow(Dor::Item).to receive(:new).and_return(item)
        allow(item).to receive(:collections).and_return([dor_collection])
        allow(item).to receive(:save!)
      end

      it 'creates collection relationship' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(Dor::Item).to have_received(:new)
          .with(pid: druid,
                admin_policy_object_id: 'druid:dd999df4567',
                source_id: 'googlebooks:999999',
                collection_ids: ['druid:xx888xx7777'],
                catkey: nil)
        expect(response.body).to equal_cocina_model(expected)
        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end

    context 'when no access is provided' do
      let(:structural) { {} }
      let(:expected_structural) { structural }

      let(:data) do
        <<~JSON
          {#{' '}
            "cocinaVersion":"#{Cocina::Models::VERSION}",
            "type":"#{Cocina::Models::ObjectType.image}",
            "label":"#{label}","version":1,
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
            "description":{"title":[{"value":"#{title}"}]},
            "identification":#{identification.to_json},
            "structural":#{structural.to_json}}
        JSON
      end

      let(:item) do
        Dor::Item.new(pid: druid,
                      admin_policy_object_id: 'druid:dd999df4567',
                      source_id: 'googlebooks:999999',
                      label: 'This is my label')
      end

      let(:collection) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:xx888xx7777',
                                       type: Cocina::Models::ObjectType.collection,
                                       label: 'Collection of new maps of Africa',
                                       version: 1,
                                       cocinaVersion: Cocina::Models::VERSION)
      end

      before do
        allow(Dor::Item).to receive(:new).and_return(item)
        allow(item).to receive(:save!)
      end

      it 'has default access' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(Dor::Item).to have_received(:new)
          .with(pid: druid,
                admin_policy_object_id: 'druid:dd999df4567',
                source_id: 'googlebooks:999999',
                collection_ids: [],
                catkey: nil)
        expect(response.body).to equal_cocina_model(expected)
        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end
  end

  context 'when a book is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.book,
                              label: expected_label,
                              version: 1,
                              description: {
                                title: [{ value: title }],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567'
                              },
                              identification: { sourceId: 'googlebooks:999999' },
                              externalIdentifier: druid,
                              structural: {
                                hasMemberOrders: [
                                  { viewingDirection: 'right-to-left' }
                                ]
                              },
                              access: {
                                view: 'world',
                                download: 'world'
                              })
    end
    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"#{label}","version":1,"access":{"view":"world","download":"world"},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"#{title}"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end
    let(:default_access) do
      {
        view: 'world',
        download: 'world'
      }
    end

    before do
      allow(SolrService).to receive(:get).and_return(no_result)
    end

    it 'registers the book and sets the viewing direction' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
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
                                          license: 'http://opendatacommons.org/licenses/by/1.0/',
                                          useAndReproductionStatement: 'Whatever makes you happy'
                                        },
                                        hasAdminPolicy: 'druid:dd999df4567',
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
              "license":"http://opendatacommons.org/licenses/by/1.0/",
              "useAndReproductionStatement":"Whatever makes you happy"
            },
            "disseminationWorkflow":"assemblyWF",
            "registrationWorkflow":["goobiWF","registrationWF"],
            "collectionsForRegistration":["druid:gg888df4567","druid:bb888gg4444"],
            "hasAdminPolicy":"druid:dd999df4567",
            "hasAgreement":"druid:bc753qt7345",
            "roles":[{"name":"dor-apo-manager","members":[{"type":"workgroup","identifier":"sdr:psm-staff"}]}]
          },
          "description":{"title":[{"value":"This is my title"}]}}
      JSON
    end

    before do
      # This stubs out Solr:
      allow_any_instance_of(Dor::AdminPolicyObject).to receive(:admin_policy_object_id).and_return('druid:dd999df4567')
    end

    context 'when the request is successful' do
      it 'registers the object with the registration service' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end

    context 'when it belongs to the Ur-AdminPolicy and create_ur_admin_policy is enabled' do
      let(:ur_apo) { instance_double(Dor::AdminPolicyObject, save!: true, add_relationship: true) }

      before do
        allow(Settings.enabled_features).to receive(:create_ur_admin_policy).and_return(true)
        allow(Settings.ur_admin_policy).to receive(:druid).and_return('druid:dd999df4567')
        allow(Dor::AdminPolicyObject).to receive(:exists?).and_return(false)
        allow(UrAdminPolicyFactory).to receive(:create)
      end

      it 'creates the Ur-AdminPolicy' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(UrAdminPolicyFactory).to have_received(:create)

        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end
  end

  context 'when a Hydrus APO is provided' do
    let(:expected) do
      Cocina::Models::AdminPolicy.new(type: Cocina::Models::ObjectType.admin_policy,
                                      label: 'Hydrus',
                                      version: 1,
                                      description: {
                                        title: [{ value: 'Hydrus' }],
                                        purl: 'https://purl.stanford.edu/gg777gg7777'
                                      },
                                      administrative: {
                                        accessTemplate: {
                                          view: 'world',
                                          download: 'world'
                                        },
                                        hasAdminPolicy: 'druid:dd999df4567',
                                        roles: [],
                                        hasAgreement: 'druid:bc753qt7345'
                                      },
                                      externalIdentifier: druid)
    end

    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.admin_policy}",
          "label":"Hydrus","version":1,
          "administrative":{
            "hasAdminPolicy":"druid:dd999df4567",
            "hasAgreement":"druid:bc753qt7345",
            "accessTemplate":{
              "view":"world",
              "download":"world"
            }}
          }
      JSON
    end

    context 'when the request is successful' do
      before do
        # This stubs out Solr:
        allow_any_instance_of(Dor::AdminPolicyObject).to receive(:admin_policy_object_id).and_return('druid:dd999df4567')
      end

      it 'registers the object with the registration service' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)

        expect(response.status).to eq(201)
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
                                hasAdminPolicy: 'druid:dd999df4567'
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
                                embargo: { view: 'world', download: 'world', releaseDate: '2020-02-29' }
                              })
    end
    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"This is my label","version":1,"access":{"view":"stanford","download":"none","controlledDigitalLending":false,
          "embargo":{"view":"world","download":"world","releaseDate":"2020-02-29"}},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end
    let(:default_access) do
      {
        view: 'stanford',
        download: 'none',
        controlledDigitalLending: false
      }
    end

    before do
      allow(SolrService).to receive(:get).and_return(no_result)
    end

    it 'registers the book and sets the rights' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
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
                                hasAdminPolicy: 'druid:dd999df4567'
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
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end
    let(:default_access) do
      {
        view: 'location-based',
        download: 'location-based',
        location: 'm&m'
      }
    end

    before do
      allow(SolrService).to receive(:get).and_return(no_result)
    end

    it 'registers the book and sets the rights' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
    end
  end

  context 'when no-download access is specified' do
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.book,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ value: 'This is my title' }],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567'
                              },
                              identification: { sourceId: 'googlebooks:999999' },
                              externalIdentifier: 'druid:gg777gg7777',
                              structural: {
                                hasMemberOrders: [
                                  { viewingDirection: 'right-to-left' }
                                ]
                              },
                              access: {
                                view: 'world',
                                download: 'none'
                              })
    end
    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"This is my label","version":1,
          "access":{"view":"world","download":"none"},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end
    let(:default_access) do
      {
        view: 'world',
        download: 'none'
      }
    end

    before do
      allow(SolrService).to receive(:get).and_return(no_result)
    end

    it 'registers the book and sets the rights' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
    end
  end

  context 'when no description is provided (registration use case)' do
    before do
      allow(SolrService).to receive(:get).and_return(no_result)
    end

    context 'when structural is provided' do
      let(:expected) do
        Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.object,
                                label: 'This is my label',
                                version: 1,
                                administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                                description: {
                                  title: [
                                    { value: 'This is my label' }
                                  ],
                                  purl: 'https://purl.stanford.edu/gg777gg7777'
                                },
                                identification: { sourceId: 'googlebooks:999999' },
                                externalIdentifier: 'druid:gg777gg7777',
                                structural: {},
                                access: {})
      end
      let(:data) do
        <<~JSON
          {#{' '}
            "cocinaVersion":"#{Cocina::Models::VERSION}",
            "type":"#{Cocina::Models::ObjectType.object}",
            "label":"This is my label","version":1,"access":{},
            "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
            "identification":{"sourceId":"googlebooks:999999"},
            "structural":{}}
        JSON
      end
      let(:default_access) do
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
        expect(response.status).to eq(201)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end

    context 'when structural is not provided' do
      let(:expected) do
        Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.object,
                                label: 'This is my label',
                                version: 1,
                                administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                                description: {
                                  title: [
                                    { value: 'This is my label' }
                                  ],
                                  purl: 'https://purl.stanford.edu/gg777gg7777'
                                },
                                identification: { sourceId: 'googlebooks:999999' },
                                externalIdentifier: 'druid:gg777gg7777',
                                access: {},
                                structural: {})
      end
      let(:data) do
        <<~JSON
          {#{' '}
            "cocinaVersion":"#{Cocina::Models::VERSION}",
            "type":"#{Cocina::Models::ObjectType.object}",
            "label":"This is my label","version":1,"access":{},
            "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
            "identification":{"sourceId":"googlebooks:999999"},
            "structural":{}
          }
        JSON
      end
      let(:default_access) do
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
        expect(response.status).to eq(201)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end

    context 'when access is not provided' do
      let(:expected) do
        Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.object,
                                label: 'This is my label',
                                version: 1,
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                                identification: { sourceId: 'googlebooks:999999' },
                                externalIdentifier: 'druid:gg777gg7777',
                                structural: {},
                                description: {
                                  title: [
                                    { value: 'This is my label' }
                                  ],
                                  purl: 'https://purl.stanford.edu/gg777gg7777'
                                })
      end

      let(:data) do
        <<~JSON
          {#{' '}
            "cocinaVersion":"#{Cocina::Models::VERSION}",
            "type":"#{Cocina::Models::ObjectType.object}",
            "label":"This is my label","version":1,
            "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
            "access":{},
            "identification":{"sourceId":"googlebooks:999999"},
            "structural":{}}
        JSON
      end
      let(:default_access) do
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
        expect(response.status).to eq(201)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end
  end

  context 'when type does not have a process tag (e.g., webarchive-binary)' do
    before do
      allow(SolrService).to receive(:get).and_return(no_result)
      allow(AdministrativeTags).to receive(:create)
    end

    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.webarchive_binary,
                              label: 'This is my label',
                              version: 1,
                              administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                              description: {
                                title: [
                                  { value: 'This is my label' }
                                ],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
                              },
                              identification: { sourceId: 'warc:999999' },
                              externalIdentifier: 'druid:gg777gg7777',
                              structural: {},
                              access: {})
    end
    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.webarchive_binary}",
          "label":"This is my label","version":1,"access":{},
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
          "identification":{"sourceId":"warc:999999"},
          "structural":{}}
      JSON
    end
    let(:default_access) do
      {
        view: 'dark',
        download: 'none'
      }
    end

    it 'registers the object and does not create process tag' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      expect(AdministrativeTags).not_to have_received(:create)
    end
  end

  context 'when type does have a process tag' do
    before do
      allow(SolrService).to receive(:get).and_return(no_result)
      allow(AdministrativeTags).to receive(:create)
    end

    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.object,
                              label: 'This is my label',
                              version: 1,
                              administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                              description: {
                                title: [
                                  { value: 'This is my label' }
                                ],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
                              },
                              identification: { sourceId: 'warc:999999' },
                              externalIdentifier: 'druid:gg777gg7777',
                              structural: {},
                              access: {})
    end
    let(:data) do
      <<~JSON
        {#{' '}
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.object}",
          "label":"This is my label","version":1,"access":{},
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
          "identification":{"sourceId":"warc:999999"},
          "structural":{}}
      JSON
    end
    let(:default_access) do
      {
        view: 'dark',
        download: 'none'
      }
    end

    it 'registers the object and creates process tag' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      expect(AdministrativeTags).to have_received(:create).with(identifier: 'druid:gg777gg7777',
                                                                tags: ['Process : Content Type : File'])
    end
  end
end

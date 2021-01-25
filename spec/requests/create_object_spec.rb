# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create object' do
  let(:apo) { Dor::AdminPolicyObject.new(pid: 'druid:dd999df4567') }
  let(:data) { item.to_json }
  let(:druid) { 'druid:gg777gg7777' }

  before do
    allow(Dor::SuriService).to receive(:mint_id).and_return(druid)
    allow(Dor).to receive(:find).and_return(apo)
    allow(Cocina::ActiveFedoraPersister).to receive(:store)
    stub_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')
  end

  context 'when an image is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:expected_structural) { { hasAgreement: 'druid:bc777df7777' } }
    let(:access) { 'world' }
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.image,
                              label: expected_label,
                              version: 1,
                              access: {
                                access: access,
                                download: 'none',
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: {
                                title: [{ value: title }]
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567',
                                partOfProject: 'Google Books'
                              },
                              identification: identification,
                              externalIdentifier: druid,
                              structural: expected_structural)
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/image.jsonld",
          "label":"#{label}","version":1,
          "access":{
            "access":"#{access}",
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
      { sourceId: 'googlebooks:999999' }
    end

    let(:structural) do
      { hasAgreement: 'druid:bc777df7777' }
    end

    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return(search_result)
    end

    context 'when the service is disabled' do
      before do
        allow(Settings.enabled_features).to receive(:registration).and_return(false)
      end

      let(:search_result) { ['druid:abc123'] }

      it 'returns a 503 error' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq 503
        expect(response.body).to eq '{"errors":[{"status":"503","title":"Service Unavailable","detail":"Registration is temporarily disabled"}]}'
      end
    end

    context 'when an object already exists' do
      let(:search_result) { ['druid:abc123'] }

      it 'returns a 409 error' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(409)
        expect(response.body).to match(/druid:abc123/)
      end
    end

    context 'when catkey is provided' do
      let(:expected_label) { title } # label derived from catalog data

      let(:identification) do
        {
          sourceId: 'googlebooks:999999',
          catalogLinks: [
            { catalog: 'symphony', catalogRecordId: '8888' }
          ]
        }
      end

      context 'when no object with the source id exists and the save is successful' do
        let(:search_result) { [] }
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
          allow(MetadataService).to receive(:fetch).and_return(mods_from_symphony)
        end

        it 'registers the object with the registration service and immediately indexes' do
          expect do
            post '/v1/objects',
                 params: data,
                 headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          end.to change(Event, :count).by(1)
          expect(a_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')).to have_been_made
          expect(response.body).to eq expected.to_json
          expect(response.status).to eq(201)
          expect(response.location).to eq "/v1/objects/#{druid}"
          expect(MetadataService).to have_received(:fetch).with('catkey:8888')
        end
      end

      context 'when connecting to symphony fails' do
        let(:search_result) { [] }

        before do
          allow(MetadataService).to receive(:fetch).and_raise(SymphonyReader::ResponseError)
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
    end

    context 'when catkey is not provided' do
      context 'when no object with the source id exists and the save is successful' do
        let(:item) do
          Dor::Item.new(pid: druid,
                        admin_policy_object_id: 'druid:dd999df4567',
                        source_id: 'googlebooks:999999',
                        label: 'This is my label')
        end

        let(:search_result) { [] }

        before do
          allow(Dor::Item).to receive(:new).and_return(item)
          allow(item).to receive(:collections).and_return([])
          allow(item).to receive(:save!)
        end

        it 'registers the object with the registration service and immediately indexes' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(a_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')).to have_been_made
          expect(response.body).to eq expected.to_json
          expect(response.status).to eq(201)
          expect(response.location).to eq "/v1/objects/#{druid}"

          # Identity metadata set correctly.
          expect(item.objectId).to eq(druid)
          expect(item.objectCreator.first).to eq('DOR')
          expect(item.objectLabel.first).to eq(expected_label)
          expect(item.objectType.first).to eq('item')
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

        let(:search_result) { [] }

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
          expect(a_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')).to have_been_made
          expect(response.body).to eq expected.to_json
          expect(response.status).to eq(201)
          expect(response.location).to eq "/v1/objects/#{druid}"

          expect(Dor::Item).to have_received(:new).with(pid: druid,
                                                        admin_policy_object_id: 'druid:dd999df4567',
                                                        source_id: 'googlebooks:999999',
                                                        collection_ids: [],
                                                        catkey: nil,
                                                        label: truncated_label)

          # Identity metadata set correctly.
          expect(item.objectLabel.first).to eq(expected_label)
          expect(item.objectType.first).to eq('item')
        end
      end
      # rubocop:enable Layout/LineLength
    end

    context 'with a hydrus object lacking a title' do
      # Hydrus has special handling of descriptive metadata
      let(:label) { 'Hydrus' }
      let(:title) { label }

      let(:item) do
        Dor::Item.new(pid: druid,
                      admin_policy_object_id: 'druid:dd999df4567',
                      source_id: 'googlebooks:999999',
                      label: label)
      end

      let(:expected_desc_md) do
        <<~XML
          <?xml version="1.0"?>
          <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title/>
            </titleInfo>
          </mods>
        XML
      end

      let(:search_result) { [] }

      before do
        allow(Dor::Item).to receive(:new).and_return(item)
        allow(item).to receive(:collections).and_return([])
        allow(item).to receive(:save!)
      end

      it 'registers the object with the registration service and immediately indexes' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(a_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')).to have_been_made
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"

        # Identity metadata set correctly.
        expect(item.objectId).to eq(druid)
        expect(item.objectCreator.first).to eq('DOR')
        expect(item.objectLabel.first).to eq(expected_label)
        expect(item.objectType.first).to eq('item')

        # Descriptive metadata set correctly.
        expect(item.descMetadata.ng_xml.to_xml).to be_equivalent_to(expected_desc_md)
      end
    end

    context 'with a hydrus object that has a title' do
      # Hydrus has special handling of descriptive metadata
      let(:label) { 'Hydrus' }
      let(:title) { 'My Very Special Hydrus Title' }

      let(:item) do
        Dor::Item.new(pid: druid,
                      admin_policy_object_id: 'druid:dd999df4567',
                      source_id: 'googlebooks:999999',
                      label: label)
      end

      let(:expected_desc_md) do
        <<~XML
          <?xml version="1.0"?>
          <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title>#{title}</title>
            </titleInfo>
          </mods>
        XML
      end

      let(:search_result) { [] }

      before do
        item.descMetadata.title_info.main_title = title
        allow(Dor::Item).to receive(:new).and_return(item)
        allow(item).to receive(:collections).and_return([])
        allow(item).to receive(:save!)
      end

      it 'registers the object with the registration service and immediately indexes' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(a_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')).to have_been_made
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"

        # Identity metadata set correctly.
        expect(item.objectId).to eq(druid)
        expect(item.objectCreator.first).to eq('DOR')
        expect(item.objectLabel.first).to eq(expected_label)
        expect(item.objectType.first).to eq('item')

        # Descriptive metadata set correctly.
        expect(item.descMetadata.ng_xml.to_xml).to be_equivalent_to(expected_desc_md)
      end
    end

    context 'when files are provided' do
      let(:search_result) { [] }
      let(:file1) do
        {
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00001.html',
          'label' => '00001.html',
          'hasMimeType' => 'text/html',
          'use' => 'transcription',
          'administrative' => {
            'sdrPreserve' => true,
            'shelve' => false
          },
          'access' => {
            'access' => 'dark'
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
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00001.jp2',
          'label' => '00001.jp2',
          'hasMimeType' => 'image/jp2',
          'administrative' => {
            'sdrPreserve' => true,
            'shelve' => true
          },
          'access' => {
            'access' => 'stanford'
          },
          'hasMessageDigests' => []
        }
      end

      let(:file3) do
        {
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00002.html',
          'label' => '00002.html',
          'hasMimeType' => 'text/html',
          'administrative' => {
            'sdrPreserve' => true,
            'shelve' => false
          },
          'access' => {
            'access' => 'world'
          },
          'hasMessageDigests' => []
        }
      end

      let(:file4) do
        {
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00002.jp2',
          'label' => '00002.jp2',
          'hasMimeType' => 'image/jp2',
          'administrative' => {
            'sdrPreserve' => true,
            'shelve' => true
          },
          'access' => {
            'access' => 'world'
          },
          'hasMessageDigests' => []
        }
      end

      let(:filesets) do
        [
          {
            'version' => 1,
            'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            'label' => 'Page 1',
            'structural' => { 'contains' => [file1, file2] }
          },
          {
            'version' => 1,
            'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            'label' => 'Page 2',
            'structural' => { 'contains' => [file3, file4] }
          }
        ]
      end

      let(:fs1) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld'
        }
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
        let(:expected_structural) do
          { contains: [
            {
              type: 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
              externalIdentifier: 'gg777gg7777_1', label: 'Page 1', version: 1,
              structural: {
                contains: [
                  {
                    type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                    externalIdentifier: 'druid:gg777gg7777/00001.html',
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
                    access: { access: 'dark', download: 'none' },
                    administrative: { sdrPreserve: true, shelve: false }
                  }, {
                    type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                    externalIdentifier: 'druid:gg777gg7777/00001.jp2',
                    label: '00001.jp2',
                    filename: '00001.jp2',
                    size: 0, version: 1,
                    hasMimeType: 'image/jp2', hasMessageDigests: [],
                    access: { access: 'world', download: 'world' },
                    administrative: { sdrPreserve: true, shelve: true }
                  }
                ]
              }
            }, {
              type: 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
              externalIdentifier: 'gg777gg7777_2',
              label: 'Page 2', version: 1,
              structural: {
                contains: [
                  {
                    type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                    externalIdentifier: 'druid:gg777gg7777/00002.html',
                    label: '00002.html', filename: '00002.html', size: 0,
                    version: 1, hasMimeType: 'text/html',
                    hasMessageDigests: [],
                    access: { access: 'world', download: 'world' },
                    administrative: { sdrPreserve: true, shelve: false }
                  }, {
                    type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                    externalIdentifier: 'druid:gg777gg7777/00002.jp2',
                    label: '00002.jp2',
                    filename: '00002.jp2',
                    size: 0, version: 1,
                    hasMimeType: 'image/jp2',
                    hasMessageDigests: [],
                    access: { access: 'world', download: 'world' },
                    administrative: { sdrPreserve: true, shelve: true }
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
                  catkey: nil, label: 'This is my label')
          expect(response.body).to eq expected.to_json
          expect(response.status).to eq(201)
          expect(item.contentMetadata.resource.file.count).to eq 4
          expect(response.location).to eq "/v1/objects/#{druid}"
        end
      end

      context 'when access mismatch' do
        let(:access) { 'dark' }

        it 'returns 400' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.status).to eq 400
          expect(response.body).to eq '{"errors":[' \
            '{"status":"400","title":"Bad Request",' \
            '"detail":"Not all files have dark access and/or are unshelved when item access is dark: ' \
            '[\\"00001.jp2\\", \\"00002.html\\", \\"00002.jp2\\"]"}]}'
        end
      end
    end

    context 'when collection is provided' do
      let(:search_result) { [] }
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

      let(:collection) { Dor::Collection.new(pid: 'druid:xx888xx7777') }

      before do
        # Allows the CollectionExistenceValidator to find the collection:
        allow(Dor).to receive(:find).with('druid:xx888xx7777').and_return(Dor::Collection.new)

        allow(Dor::Item).to receive(:new).and_return(item)
        allow(item).to receive(:collections).and_return([collection])
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
                catkey: nil, label: 'This is my label')
        expect(response.body).to eq expected.to_json
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
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.book,
                              label: expected_label,
                              version: 1,
                              description: {
                                title: [{ value: title }]
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
                                access: 'world',
                                download: 'world'
                              })
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"#{label}","version":1,"access":{"access":"world","download":"world"},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"#{title}"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end

    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
    end

    it 'registers the book and sets the viewing direction' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to eq expected.to_json
      expect(response.status).to eq(201)
      expect(response.location).to eq "/v1/objects/#{druid}"
    end
  end

  context 'when an APO is provided' do
    let(:expected) do
      Cocina::Models::AdminPolicy.new(type: Cocina::Models::Vocab.admin_policy,
                                      label: 'This is my label',
                                      version: 1,
                                      description: {
                                        title: [{ value: 'This is my title' }]
                                      },
                                      administrative: {
                                        defaultObjectRights: default_object_rights,
                                        hasAdminPolicy: 'druid:dd999df4567',
                                        registrationWorkflow: 'assemblyWF'
                                      },
                                      externalIdentifier: druid)
    end

    let(:default_object_rights) { Dor::DefaultObjectRightsDS.new.content }

    let(:data) do
      <<~JSON
        {"type":"http://cocina.sul.stanford.edu/models/admin_policy.jsonld",
          "label":"This is my label","version":1,
          "administrative":{
            "defaultObjectRights":#{default_object_rights.to_json},
            "registrationWorkflow":"assemblyWF",
            "hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"This is my title"}]}}
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
        expect(response.body).to eq expected.to_json

        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end
  end

  context 'when an embargo is provided' do
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.book,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ value: 'This is my title' }]
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
                                access: 'stanford',
                                download: 'none',
                                embargo: { access: 'world', releaseDate: '2020-02-29' }
                              })
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"This is my label","version":1,"access":{"access":"stanford",
          "embargo":{"access":"world","releaseDate":"2020-02-29"}},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end

    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
    end

    it 'registers the book and sets the rights' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to eq expected.to_json
      expect(response.status).to eq(201)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
    end
  end

  context 'when location access is specified' do
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.book,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ value: 'This is my title' }]
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
                                access: 'location-based',
                                download: 'location-based',
                                readLocation: 'm&m'
                              })
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"This is my label","version":1,
          "access":{"access":"location-based","readLocation":"m&m"},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end

    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
    end

    it 'registers the book and sets the rights' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to eq expected.to_json
      expect(response.status).to eq(201)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
    end
  end

  context 'when no-download access is specified' do
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.book,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ value: 'This is my title' }]
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
                                access: 'world',
                                download: 'none'
                              })
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"This is my label","version":1,
          "access":{"access":"world","download":"none"},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end

    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
    end

    it 'registers the book and sets the rights' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response.body).to eq expected.to_json
      expect(response.status).to eq(201)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
    end
  end

  context 'when no description is provided (registration use case)' do
    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
    end

    context 'when structural is provided' do
      let(:expected) do
        Cocina::Models::DRO.new(type: Cocina::Models::Vocab.object,
                                label: 'This is my label',
                                version: 1,
                                administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                                description: { title: [{ value: 'This is my label' }] },
                                identification: { sourceId: 'googlebooks:999999' },
                                externalIdentifier: 'druid:gg777gg7777',
                                structural: {},
                                access: { access: 'world' })
      end
      let(:data) do
        <<~JSON
          { "type":"http://cocina.sul.stanford.edu/models/object.jsonld",
            "label":"This is my label","version":1,"access":{"access":"world"},
            "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
            "identification":{"sourceId":"googlebooks:999999"},
            "structural":{}}
        JSON
      end

      it 'registers the object' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(201)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end

    context 'when structural is not provided' do
      let(:expected) do
        Cocina::Models::DRO.new(type: Cocina::Models::Vocab.object,
                                label: 'This is my label',
                                version: 1,
                                administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                                description: { title: [{ value: 'This is my label' }] },
                                identification: { sourceId: 'googlebooks:999999' },
                                externalIdentifier: 'druid:gg777gg7777',
                                structural: {},
                                access: { access: 'world' })
      end
      let(:data) do
        <<~JSON
          { "type":"http://cocina.sul.stanford.edu/models/object.jsonld",
            "label":"This is my label","version":1,"access":{"access":"world"},
            "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
            "identification":{"sourceId":"googlebooks:999999"}}
        JSON
      end

      it 'registers the object' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(201)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end

    context 'when access is not provided' do
      let(:expected) do
        Cocina::Models::DRO.new(type: Cocina::Models::Vocab.object,
                                label: 'This is my label',
                                version: 1,
                                access: {
                                  access: 'world',
                                  download: 'world',
                                  copyright: 'resides with the creators',
                                  useAndReproductionStatement: 'You can use it'
                                },
                                administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                                identification: { sourceId: 'googlebooks:999999' },
                                externalIdentifier: 'druid:gg777gg7777',
                                structural: {},
                                description: { "title": [{ "value": 'This is my label' }] })
      end

      let(:data) do
        <<~JSON
          { "type":"http://cocina.sul.stanford.edu/models/object.jsonld",
            "label":"This is my label","version":1,
            "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
            "identification":{"sourceId":"googlebooks:999999"},
            "structural":{}}
        JSON
      end

      before do
        apo.defaultObjectRights.content = <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world/>
              </machine>
            </access>
            <use>
              <human type="useAndReproduction">You can use it</human>
            </use>
            <copyright>
              <human>resides with the creators</human>
            </copyright>
          </rightsMetadata>
        XML
      end

      it 'inherits access, copyright and use statement from the admin policy' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(201)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end
  end

  context 'when type does not have a process tag (e.g., webarchive-binary)' do
    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
      allow(AdministrativeTags).to receive(:create)
    end

    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.object,
                              label: 'This is my label',
                              version: 1,
                              administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                              description: { title: [{ value: 'This is my label' }] },
                              identification: { sourceId: 'warc:999999' },
                              externalIdentifier: 'druid:gg777gg7777',
                              structural: {},
                              access: { access: 'world' })
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/webarchive-binary.jsonld",
          "label":"This is my label","version":1,"access":{"access":"world"},
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
          "identification":{"sourceId":"warc:999999"},
          "structural":{}}
      JSON
    end

    it 'registers the object and does not create process tag' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to eq expected.to_json
      expect(response.status).to eq(201)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      expect(AdministrativeTags).not_to have_received(:create)
    end
  end

  context 'when type does have a process tag' do
    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
      allow(AdministrativeTags).to receive(:create)
    end

    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.object,
                              label: 'This is my label',
                              version: 1,
                              administrative: { hasAdminPolicy: 'druid:dd999df4567' },
                              description: { title: [{ value: 'This is my label' }] },
                              identification: { sourceId: 'warc:999999' },
                              externalIdentifier: 'druid:gg777gg7777',
                              structural: {},
                              access: { access: 'world' })
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/object.jsonld",
          "label":"This is my label","version":1,"access":{"access":"world"},
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
          "identification":{"sourceId":"warc:999999"},
          "structural":{}}
      JSON
    end

    it 'registers the object and creates process tag' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to eq expected.to_json
      expect(response.status).to eq(201)
      expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      expect(AdministrativeTags).to have_received(:create).with(pid: 'druid:gg777gg7777',
                                                                tags: ['Process : Content Type : File'])
    end
  end
end

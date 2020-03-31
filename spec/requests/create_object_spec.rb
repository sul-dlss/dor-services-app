# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create object' do
  let(:object) { Dor::AdminPolicyObject.new(pid: 'druid:dd999df4567') }
  let(:data) { item.to_json }
  let(:druid) { 'druid:gg777gg7777' }

  before do
    allow(Dor::SuriService).to receive(:mint_id).and_return(druid)
    allow(Dor).to receive(:find).and_return(object)
    stub_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')
  end

  context 'when an image is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:structural) { {} }
    let(:access) { 'world' }
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.image,
                              label: expected_label,
                              version: 1,
                              access: {
                                access: access,
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: {
                                title: [{ value: title, status: 'primary' }]
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567',
                                partOfProject: 'Google Books'
                              },
                              identification: identification,
                              externalIdentifier: druid,
                              structural: structural)
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
          "description":{"title":[{"status":"primary","value":"#{title}"}]},
          "identification":#{identification.to_json},"structural":{}}
      JSON
    end

    let(:identification) do
      { sourceId: 'googlebooks:999999' }
    end

    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return(search_result)
    end

    context 'when an object already exists' do
      let(:search_result) { ['item'] }

      it 'returns a 409 error' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(409)
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

        before do
          allow_any_instance_of(Dor::Item).to receive(:save!)
          allow(RefreshMetadataAction).to receive(:run)
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
          expect(RefreshMetadataAction).to have_received(:run)
            .with(identifiers: ['catkey:8888'], datastream: Dor::DescMetadataDS)
        end
      end
    end

    context 'when catkey is not provided' do
      context 'when no object with the source id exists and the save is successful' do
        let(:search_result) { [] }

        before do
          allow_any_instance_of(Dor::Item).to receive(:save!)
        end

        it 'registers the object with the registration service and immediately indexes' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(a_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')).to have_been_made
          expect(response.body).to eq expected.to_json
          expect(response.status).to eq(201)
          expect(response.location).to eq "/v1/objects/#{druid}"
        end
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
      let(:data) do
        <<~JSON
          { "type":"http://cocina.sul.stanford.edu/models/image.jsonld",
            "label":"#{label}","version":1,"access":{"access":"#{access}"},
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
            "description":{"title":[{"status":"primary","value":"#{title}"}]},
            "identification":#{identification.to_json},"structural":{"contains":#{filesets.to_json}}}
        JSON
      end

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
        allow(item).to receive(:collection_ids).and_return([])
        allow(item).to receive(:save!)
      end

      context 'when access match' do
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
          expect(response.status).to eq(400)
          expect(response.body).to eq('Not all files have dark access and/or are unshelved when item access is dark: ["00001.jp2", "00002.html", "00002.jp2"]')
        end
      end
    end

    context 'when collection is provided' do
      let(:search_result) { [] }
      let(:structural) { { isMemberOf: 'druid:xx888xx7777' } }

      let(:data) do
        <<~JSON
          { "type":"http://cocina.sul.stanford.edu/models/image.jsonld",
            "label":"#{label}","version":1,"access":{"access":"world"},
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
            "description":{"title":[{"status":"primary","value":"#{title}"}]},
            "identification":#{identification.to_json},"structural":{"isMemberOf":"druid:xx888xx7777"}}
        JSON
      end

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
        allow(item).to receive(:collection_ids).and_return(['druid:xx888xx7777'])
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
                                title: [{ value: title, status: 'primary' }]
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
                              access: { access: 'world' })
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"#{label}","version":1,"access":{"access":"world"},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"status":"primary","value":"#{title}"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end

    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
      allow_any_instance_of(Dor::Item).to receive(:save!)
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

  context 'when a collection is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:expected) do
      Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                     label: expected_label,
                                     version: 1,
                                     description: {
                                       title: [{ value: title, status: 'primary' }]
                                     },
                                     administrative: {
                                       hasAdminPolicy: 'druid:dd999df4567'
                                     },
                                     externalIdentifier: druid,
                                     access: {})
    end
    let(:data) do
      <<~JSON
        {"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
          "label":"#{label}","version":1,"access":{},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"status":"primary","value":"#{title}"}]}}
      JSON
    end

    context 'when the catkey is provided and save is successful' do
      let(:expected_label) { title } # label derived from catalog data
      let(:data) do
        <<~JSON
          {"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
            "label":"#{label}","version":1,"access":{},
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
            "description":{"title":[{"status":"primary","value":"#{title}"}]},
            "identification":#{identification.to_json}}
        JSON
      end

      let(:expected) do
        Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                       label: expected_label,
                                       version: 1,
                                       description: {
                                         title: [{ value: title, status: 'primary' }]
                                       },
                                       administrative: {
                                         hasAdminPolicy: 'druid:dd999df4567'
                                       },
                                       identification: identification,
                                       externalIdentifier: druid,
                                       access: {})
      end

      let(:identification) do
        {
          catalogLinks: [
            { catalog: 'symphony', catalogRecordId: '8888' }
          ]
        }
      end

      before do
        allow_any_instance_of(Dor::Collection).to receive(:save!)
        allow(RefreshMetadataAction).to receive(:run)
      end

      it 'creates the collection' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json

        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
        expect(RefreshMetadataAction).to have_received(:run)
          .with(identifiers: ['catkey:8888'], datastream: Dor::DescMetadataDS)
      end
    end

    context 'when the catkey is not provided and save is successful' do
      before do
        allow_any_instance_of(Dor::Collection).to receive(:save!)
      end

      it 'creates the collection' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json

        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end
  end

  context 'when an APO is provided' do
    let(:expected) do
      Cocina::Models::AdminPolicy.new(type: Cocina::Models::Vocab.admin_policy,
                                      label: 'This is my label',
                                      version: 1,
                                      description: {
                                        title: [{ value: 'This is my title', status: 'primary' }]
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
          "description":{"title":[{"status":"primary","value":"This is my title"}]}}
      JSON
    end

    context 'when the request is successful' do
      before do
        allow_any_instance_of(Dor::AdminPolicyObject).to receive(:save!)
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
                                title: [{ value: 'This is my title', status: 'primary' }]
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
                              access: { access: 'citation-only', embargo: { access: 'world', releaseDate: '2020-02-29' } })
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"This is my label","version":1,"access":{"access":"world",
          "embargo":{"access":"world","releaseDate":"2020-02-29"}},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"status":"primary","value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end

    before do
      allow(Dor::SearchService).to receive(:query_by_id).and_return([])
      allow_any_instance_of(Dor::Item).to receive(:save!)
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
end

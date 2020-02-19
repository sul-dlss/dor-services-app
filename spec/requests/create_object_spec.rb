# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create object' do
  let(:object) { Dor::AdminPolicyObject.new(pid: 'druid:dd999df4567') }
  let(:data) { item.to_json }

  before do
    allow(Dor::SuriService).to receive(:mint_id).and_return('druid:gg777gg7777')
    allow(Dor).to receive(:find).and_return(object)
  end

  context 'when an item is provided' do
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.image,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ titleFull: 'This is my title', primary: true }]
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567'
                              },
                              identification: identification,
                              externalIdentifier: 'druid:gg777gg7777',
                              structural: {
                                hasMemberOrders: [
                                  { viewingDirection: 'right-to-left' }
                                ]
                              })
    end
    let(:data) do
      <<~JSON
        { "type":"http://cocina.sul.stanford.edu/models/image.jsonld",
          "label":"This is my label","version":1,"access":{},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"primary":true,"titleFull":"This is my title"}]},
          "identification":#{identification.to_json},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
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

        it 'registers the object with the registration service' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

          expect(response.body).to eq expected.to_json
          expect(response.status).to eq(201)
          expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
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

        it 'registers the object with the registration service' do
          post '/v1/objects',
               params: data,
               headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

          expect(response.body).to eq expected.to_json
          expect(response.status).to eq(201)
          expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
        end
      end
    end
  end

  context 'when a collection is provided' do
    let(:expected) do
      Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                     label: 'This is my label',
                                     version: 1,
                                     description: {
                                       title: [{ titleFull: 'This is my title', primary: true }]
                                     },
                                     administrative: {
                                       hasAdminPolicy: 'druid:dd999df4567'
                                     },
                                     identification: identification,
                                     externalIdentifier: 'druid:gg777gg7777')
    end
    let(:identification) { {} }
    let(:data) do
      <<~JSON
        {"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
          "label":"This is my label","version":1,"access":{},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"primary":true,"titleFull":"This is my title"}]},
          "identification":#{identification.to_json},
          "structural":{}}
      JSON
    end

    context 'when the catkey is provided and save is successful' do
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
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
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
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end
  end

  context 'when an APO is provided' do
    let(:expected) do
      Cocina::Models::AdminPolicy.new(type: Cocina::Models::Vocab.admin_policy,
                                      label: 'This is my label',
                                      version: 1,
                                      description: {
                                        title: [{ titleFull: 'This is my title', primary: true }]
                                      },
                                      administrative: {
                                        hasAdminPolicy: 'druid:dd999df4567',
                                        registration_workflow: 'assemblyWF'
                                      },
                                      externalIdentifier: 'druid:gg777gg7777')
    end

    let(:default_object_rights) { Dor::DefaultObjectRightsDS.new.content.to_json }

    let(:data) do
      <<~JSON
        {"type":"http://cocina.sul.stanford.edu/models/admin_policy.jsonld",
          "label":"This is my label","version":1,"access":{},
          "administrative":{
            "default_object_rights":#{default_object_rights},
          "registration_workflow":"assemblyWF",
          "hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"primary":true,"titleFull":"This is my title"}]},
          "identification":{},"structural":{}}
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
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end
  end
end

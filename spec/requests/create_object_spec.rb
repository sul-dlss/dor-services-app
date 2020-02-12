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
    let(:item) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.image,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ titleFull: 'This is my title', primary: true }]
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567'
                              },
                              identification: {
                                sourceId: 'googlebooks:999999'
                              },
                              externalIdentifier: 'druid:bc123df4567') # TODO: can we get rid of this?
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

    context 'when no object with the source id exists and the request is successful' do
      let(:search_result) { [] }

      before do
        allow_any_instance_of(Dor::Item).to receive(:save!)
      end

      it 'registers the object with the registration service' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq Cocina::Models::DRO.new(item.attributes.merge(externalIdentifier: 'druid:gg777gg7777')).to_json

        expect(response.status).to eq(201)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end
  end

  context 'when a collection is provided' do
    let(:item) do
      Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                     label: 'This is my label',
                                     version: 1,
                                     description: {
                                       title: [{ titleFull: 'This is my title', primary: true }]
                                     },
                                     administrative: {
                                       hasAdminPolicy: 'druid:dd999df4567'
                                     },
                                     externalIdentifier: 'druid:bc123df4567') # TODO: can we get rid of this?
    end


    context 'when the request is successful' do
      before do
        allow_any_instance_of(Dor::Collection).to receive(:save!)
      end

      it 'registers the object with the registration service' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq Cocina::Models::Collection.new(item.attributes.merge(externalIdentifier: 'druid:gg777gg7777')).to_json

        expect(response.status).to eq(201)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end
  end

  context 'when an APO is provided' do
    let(:item) do
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
                                      externalIdentifier: 'druid:bc123df4567') # TODO: can we get rid of this?
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
        expect(response.body).to eq Cocina::Models::AdminPolicy.new(item.attributes.merge(externalIdentifier: 'druid:gg777gg7777')).to_json

        expect(response.status).to eq(201)
        expect(response.location).to eq '/v1/objects/druid:gg777gg7777'
      end
    end
  end
end

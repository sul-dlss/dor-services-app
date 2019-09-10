# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch creation of virtual objects' do
  let(:payload) { { sub: 'argo' } }
  let(:jwt) { JWT.encode(payload, Settings.dor.hmac_secret, 'HS256') }
  let(:parent_id) { 'druid:mk420bs7601' }
  let(:child1_id) { 'druid:child1' }
  let(:child2_id) { 'druid:child2' }

  let(:object) { Dor::Item.new(pid: parent_id) }
  let(:service) { instance_double(ConstituentService, add: nil) }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(ConstituentService).to receive(:new).with(parent_druid: parent_id).and_return(service)
  end

  context 'when virtual_objects param is provided' do
    it 'creates a virtual object out of the parent object and all child objects' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: parent_id, child_ids: [child1_id, child2_id] }] },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).to have_received(:add).with(child_druids: [child1_id, child2_id])
      expect(response).to be_successful
    end
  end

  context 'when virtual_objects contain objects that are not combinable' do
    before do
      allow(service).to receive(:add).and_return(parent_id => ["Item #{child2_id} is not open for modification"])
    end

    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: parent_id, child_ids: [child1_id, child2_id] }] },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).to have_received(:add).with(child_druids: [child1_id, child2_id])
      expect(response).to be_unprocessable
      expect(response.body).to eq '{"errors":[{"druid:mk420bs7601":["Item druid:child2 is not open for modification"]}]}'
    end
  end

  context 'when virtual_objects param is not provided' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { title: 'New name' },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['text']).to eq 'virtual_objects is missing'
    end
  end

  context 'when virtual_objects is not an array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: child1_id },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['text']).to eq 'virtual_objects must be an array'
    end
  end

  context 'when virtual_objects is empty array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [] },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['text']).to eq 'parent_id is missing'
    end
  end

  context 'when virtual_objects array lacks hashes defining parent_id' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ child_ids: ['foo'] }] },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['text']).to eq 'parent_id is missing'
    end
  end

  context 'when virtual_objects array has a hash w/ an empty parent_id' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: '' }] },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['text']).to eq 'parent_id must be filled'
    end
  end

  context 'when virtual_objects array lacks hashes defining child_ids' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'foo' }] },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['text']).to eq 'child_ids is missing'
    end
  end

  context 'when virtual_objects array has a hash w/ child_ids not an array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'foo', child_ids: '' }] },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['text']).to eq 'child_ids must be an array'
    end
  end

  context 'when virtual_objects array has a hash w/ child_ids empty' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'foo', child_ids: [] }] },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['text']).to eq '0 must be filled'
    end
  end

  context 'when virtual_objects array has a hash w/ child_ids containing empties' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'foo', child_ids: ['foo', 'bar', ''] }] },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['text']).to eq '2 must be filled'
    end
  end
end

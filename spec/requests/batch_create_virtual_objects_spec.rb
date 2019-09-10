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

  context 'when virtual_objects param is not provided' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { title: 'New name' },
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['detail']).to eq 'param is missing or the value is empty: virtual_objects'
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
      expect(json['errors'][0]['detail']).to eq 'param is missing or the value is empty: virtual_objects must be an array'
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
end

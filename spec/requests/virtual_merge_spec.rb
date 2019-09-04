# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Virtual merge of objects' do
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

  context 'when constituent_ids is provided' do
    it 'merges the objects' do
      put "/v1/objects/#{parent_id}",
          params: { constituent_ids: [child1_id, child2_id] },
          headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).to have_received(:add).with(child_druids: [child1_id, child2_id])
      expect(response).to be_successful
    end
  end

  context 'when constituent_ids is not provided' do
    it 'renders an error' do
      put "/v1/objects/#{parent_id}",
          params: { title: 'New name' },
          headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['detail']).to eq 'param is missing or the value is empty: constituent_ids'
    end
  end

  context 'when constituent_ids is not an array' do
    it 'renders an error' do
      put "/v1/objects/#{parent_id}",
          params: { constituent_ids: child1_id },
          headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).not_to have_received(:add)
      expect(response).to be_bad_request
      json = JSON.parse(response.body)
      expect(json['errors'][0]['detail']).to eq 'param is missing or the value is empty: constituent_ids must be an array'
    end
  end

  context 'when constituent_ids contain objects that are not combinable' do
    before do
      allow(service).to receive(:add).and_return(child2_id => "Item #{child2_id} is not open for modification")
    end

    it 'renders an error' do
      put "/v1/objects/#{parent_id}",
          params: { constituent_ids: [child1_id, child2_id] },
          headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(service).to have_received(:add).with(child_druids: [child1_id, child2_id])
      expect(response).to be_unprocessable
      json = JSON.parse(response.body)
      expect(json['errors']).to eq '{"druid:child2":"Item druid:child2 is not open for modification"}'
    end
  end
end

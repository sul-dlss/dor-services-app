# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch creation of virtual objects' do
  let(:child1_id) { 'druid:kx420bs7601' }
  let(:child2_id) { 'druid:sb340kx7205' }
  # We use `#with_indifferent_access` here to mimic how Rails parses JSON parameters
  let(:body) { JSON.parse(response.body).with_indifferent_access }
  let(:parent_id) { 'druid:mk420bs7601' }
  let(:virtual_objects) { [{ parent_id: parent_id, child_ids: [child1_id, child2_id] }] }
  let(:druid_pattern) { '^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$' }

  before do
    # Do not actually kick off a job; that is tested elsewhere.
    allow(CreateVirtualObjectsJob).to receive(:perform_later)
  end

  context 'when virtual_objects param is provided' do
    it 'queues a background job to create a virtual object' do
      post '/v1/virtual_objects',
           params: { virtual_objects: virtual_objects }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).to have_received(:perform_later)
        .with(virtual_objects: virtual_objects, background_job_result: instance_of(BackgroundJobResult)).once
      expect(response).to have_http_status(:created)
      expect(response.location).to match(%r{http://www.example.com/v1/background_job_results/\d+})
    end
  end

  context 'when virtual_objects param is not provided' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { title: 'New name' }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail']).to eq('#/paths/~1v1~1virtual_objects/post/requestBody/content/application~1json/schema missing required parameters: virtual_objects')
    end
  end

  context 'when virtual_objects is not an array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: child1_id }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail']).to eq('#/paths/~1v1~1virtual_objects/post/requestBody/content/application~1json/schema/properties/virtual_objects ' \
        "expected array, but received String: #{child1_id}")
    end
  end

  context 'when virtual_objects is empty array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail']).to eq('#/paths/~1v1~1virtual_objects/post/requestBody/content/application~1json/schema/properties/virtual_objects [] contains fewer than min items')
    end
  end

  context 'when virtual_objects array lacks hashes defining parent_id' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ child_ids: ['druid:bb111cc3333'] }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail']).to eq('#/components/schemas/VirtualObjectRequest missing required parameters: parent_id')
    end
  end

  context 'when virtual_objects array has a hash w/ an empty parent_id' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: '' }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail']).to eq("#/components/schemas/Druid pattern #{druid_pattern} does not match value: , example: druid:bc123df4567")
    end
  end

  context 'when virtual_objects array lacks hashes defining child_ids' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'druid:bb111cc3333' }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail']).to eq('#/components/schemas/VirtualObjectRequest missing required parameters: child_ids')
    end
  end

  context 'when virtual_objects array has a hash w/ child_ids not an array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'druid:bb111cc3333', child_ids: '' }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail']).to eq('#/components/schemas/VirtualObjectRequest/properties/child_ids expected array, but received String: ')
    end
  end

  context 'when virtual_objects array has a hash w/ child_ids empty' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'druid:bb111cc3333', child_ids: [] }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail']).to eq('#/components/schemas/VirtualObjectRequest/properties/child_ids [] contains fewer than min items')
    end
  end

  context 'when virtual_objects array has a hash w/ child_ids containing empties' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'druid:bb111cc3333', child_ids: ['druid:ff111cc3333', 'druid:cc111dd3333', ''] }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail']).to eq("#/components/schemas/Druid pattern #{druid_pattern} does not match value: , example: druid:bc123df4567")
    end
  end
end

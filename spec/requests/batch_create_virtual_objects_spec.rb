# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch creation of virtual objects' do
  let(:constituent1_id) { 'druid:kx420bs7601' }
  let(:constituent2_id) { 'druid:sb340kx7205' }
  # We use `#with_indifferent_access` here to mimic how Rails parses JSON parameters
  let(:body) { JSON.parse(response.body).with_indifferent_access } # rubocop:disable Rails/ResponseParsedBody
  let(:virtual_object_id) { 'druid:mk420bs7601' }
  let(:virtual_objects) { [{ virtual_object_id:, constituent_ids: [constituent1_id, constituent2_id] }] }
  let(:druid_pattern) { '^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$' }

  before do
    # Do not actually kick off a job; that is tested elsewhere.
    allow(CreateVirtualObjectsJob).to receive(:perform_later)
  end

  context 'when virtual_objects param is provided' do
    it 'queues a background job to create a virtual object' do
      post '/v1/virtual_objects',
           params: { virtual_objects: }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).to have_received(:perform_later)
        .with(virtual_objects:, background_job_result: instance_of(BackgroundJobResult)).once
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
      expect(body['errors'][0]['detail'])
        .to eq('object at root is missing required properties: virtual_objects')
    end
  end

  context 'when virtual_objects is not an array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: constituent1_id }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail'])
        .to eq('value at `/virtual_objects` is not an array')
    end
  end

  context 'when virtual_objects is empty array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail'])
        .to eq('array size at `/virtual_objects` is less than: 1')
    end
  end

  context 'when virtual_objects array lacks hashes defining virtual_object_id' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ constituent_ids: ['druid:bb111cc3333'] }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail'])
        .to eq('object at `/virtual_objects/0` is missing required properties: virtual_object_id')
    end
  end

  context 'when virtual_objects array has a hash w/ an empty virtual_object_id' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ virtual_object_id: '' }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail'])
        .to eq('string at `/virtual_objects/0/virtual_object_id` does not match pattern: ' \
               '^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$; ' \
               'object at `/virtual_objects/0` is missing required properties: constituent_ids')
    end
  end

  context 'when virtual_objects array lacks hashes defining constituent_ids' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ virtual_object_id: 'druid:bb111cc3333' }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail'])
        .to eq('object at `/virtual_objects/0` is missing required properties: constituent_ids')
    end
  end

  context 'when virtual_objects array has a hash w/ constituent_ids not an array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ virtual_object_id: 'druid:bb111cc3333', constituent_ids: '' }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail'])
        .to eq('value at `/virtual_objects/0/constituent_ids` is not an array')
    end
  end

  context 'when virtual_objects array has a hash w/ constituent_ids empty' do
    it 'queues a background job to create a virtual object' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ virtual_object_id: 'druid:bb111cc3333', constituent_ids: [] }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).to have_received(:perform_later)
      expect(response).to have_http_status(:created)
      expect(response.location).to match(%r{http://www.example.com/v1/background_job_results/\d+})
    end
  end

  context 'when virtual_objects array has a hash w/ constituent_ids containing empties' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ virtual_object_id: 'druid:bb111cc3333',
                                         constituent_ids: ['druid:ff111cc3333', 'druid:cc111dd3333', ''] }] }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['detail'])
        .to eq('string at `/virtual_objects/0/constituent_ids/2` does not match pattern: ^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$') # rubocop:disable Layout/LineLength
    end
  end
end

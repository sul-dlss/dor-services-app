# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch creation of virtual objects' do
  let(:child1_id) { 'druid:child1' }
  let(:child2_id) { 'druid:child2' }
  # We use `#with_indifferent_access` here to mimic how Rails parses JSON parameters
  let(:body) { JSON.parse(response.body).with_indifferent_access }
  let(:parent_id) { 'druid:mk420bs7601' }
  let(:virtual_objects) { [{ parent_id: parent_id, child_ids: [child1_id, child2_id] }] }

  before do
    # Do not actually kick off a job; that is tested elsewhere.
    allow(CreateVirtualObjectsJob).to receive(:perform_later)
  end

  context 'when virtual_objects param is provided' do
    it 'queues a background job to create a virtual object' do
      post '/v1/virtual_objects',
           params: { virtual_objects: virtual_objects },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).to have_received(:perform_later)
        .with(virtual_objects: virtual_objects, background_job_result: instance_of(BackgroundJobResult)).once
      expect(response).to have_http_status(:created)
      expect(response.location).to match(%r{http://www.example.com/v1/background_job_results/\d+})
    end
  end

  context 'when virtual_objects param is not provided' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { title: 'New name' },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['text']).to eq('virtual_objects is missing')
    end
  end

  context 'when virtual_objects is not an array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: child1_id },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['text']).to eq('virtual_objects must be an array')
    end
  end

  context 'when virtual_objects is empty array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [] },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['text']).to eq('parent_id is missing')
    end
  end

  context 'when virtual_objects array lacks hashes defining parent_id' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ child_ids: ['foo'] }] },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['text']).to eq('parent_id is missing')
    end
  end

  context 'when virtual_objects array has a hash w/ an empty parent_id' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: '' }] },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['text']).to eq('parent_id must be filled')
    end
  end

  context 'when virtual_objects array lacks hashes defining child_ids' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'foo' }] },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['text']).to eq('child_ids is missing')
    end
  end

  context 'when virtual_objects array has a hash w/ child_ids not an array' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'foo', child_ids: '' }] },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['text']).to eq('child_ids must be an array')
    end
  end

  context 'when virtual_objects array has a hash w/ child_ids empty' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'foo', child_ids: [] }] },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['text']).to eq('0 must be filled')
    end
  end

  context 'when virtual_objects array has a hash w/ child_ids containing empties' do
    it 'renders an error' do
      post '/v1/virtual_objects',
           params: { virtual_objects: [{ parent_id: 'foo', child_ids: ['foo', 'bar', ''] }] },
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CreateVirtualObjectsJob).not_to have_received(:perform_later)
      expect(response).to have_http_status(:bad_request)
      expect(body['errors'][0]['text']).to eq('2 must be filled')
    end
  end
end

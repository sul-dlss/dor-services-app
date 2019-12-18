# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Publish object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(PublishJob).to receive(:perform_later)
  end

  context 'with a workflow provided' do
    it 'calls PublishMetadataService and returns 201' do
      post "/v1/objects/#{druid}/publish?workflow=releaseWF", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(PublishJob).to have_received(:perform_later)
        .with(druid: druid, background_job_result: BackgroundJobResult, workflow: 'releaseWF')
      expect(response.status).to eq(201)
    end
  end

  context 'with an invalid workflow provided' do
    let(:error) { JSON.parse(response.body)['errors'][0]['detail'] }

    it 'is a bad request' do
      post "/v1/objects/#{druid}/publish?workflow=badWF", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:bad_request)
      expect(error).to eq("badWF isn't include enum in #/paths/~1v1~1objects~1{id}~1publish/post/parameters/1/schema")
    end
  end

  context 'without a workflow provided' do
    # This happens when Argo invokes the API
    it 'calls PublishMetadataService and returns 201' do
      post "/v1/objects/#{druid}/publish", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(PublishJob).to have_received(:perform_later)
        .with(druid: druid, background_job_result: BackgroundJobResult, workflow: nil)
      expect(response.status).to eq(201)
    end
  end
end

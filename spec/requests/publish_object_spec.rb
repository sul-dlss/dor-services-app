# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Publish object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:job) { class_double(PublishJob, perform_later: nil) }

  before do
    allow(CocinaObjectStore).to receive(:exists!).with(druid)
    allow(PublishJob).to receive(:set).and_return(job)
  end

  context 'with a workflow provided' do
    it 'calls Publish::MetadataTransferService and returns 201' do
      post "/v1/objects/#{druid}/publish?workflow=releaseWF&lane-id=low", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(PublishJob).to have_received(:set).with(queue: :publish_low)
      expect(job).to have_received(:perform_later)
        .with(druid:, background_job_result: BackgroundJobResult, workflow: 'releaseWF')
      expect(response).to have_http_status(:created)
    end
  end

  context 'with an invalid workflow provided' do
    let(:error) { JSON.parse(response.body)['errors'][0]['detail'] } # rubocop:disable Rails/ResponseParsedBody

    it 'is a bad request' do
      post "/v1/objects/#{druid}/publish?workflow=badWF", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:bad_request)
      expect(error).to eq("\"badWF\" isn't part of the enum in #/paths/~1v1~1objects~1{id}~1publish/post/parameters/1/schema")
    end
  end

  context 'without a workflow provided' do
    # This happens when Argo invokes the API
    it 'calls Publish::MetadataTransferService and returns 201' do
      post "/v1/objects/#{druid}/publish", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(job).to have_received(:perform_later)
        .with(druid:, background_job_result: BackgroundJobResult, workflow: nil)
      expect(response).to have_http_status(:created)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Publish object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:job) { class_double(PublishJob, perform_later: nil) }

  before do
    allow(CocinaObjectStore).to receive(:exists!).with(druid)
    allow(PublishJob).to receive(:set).and_return(job)
  end

  # This happens when Argo invokes the API
  it 'calls Publish::MetadataTransferService and returns 201' do
    post "/v1/objects/#{druid}/publish", headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(job).to have_received(:perform_later)
      .with(druid:, background_job_result: BackgroundJobResult)
    expect(response).to have_http_status(:created)
  end
end

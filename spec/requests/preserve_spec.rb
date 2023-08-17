# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Preserve object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:job) { class_double(PreserveJob, perform_later: nil) }

  before do
    allow(CocinaObjectStore).to receive(:exists!).with(druid)
    allow(PreserveJob).to receive(:set).and_return(job)
  end

  it 'initiates PreserveJob and returns 201' do
    post "/v1/objects/#{druid}/preserve?lane-id=low", headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(PreserveJob).to have_received(:set).with(queue: :low)
    expect(job).to have_received(:perform_later).with(druid:, background_job_result: BackgroundJobResult)
    expect(response).to have_http_status(:created)
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset workspace' do
  let(:druid) { 'druid:bb222cc3333' }
  let(:job) { class_double(ResetWorkspaceJob, perform_later: nil) }

  before do
    allow(CocinaObjectStore).to receive(:version).and_return(2)
    allow(ResetWorkspaceJob).to receive(:set).and_return(job)
  end

  context 'when the request is succcessful' do
    it 'is successful' do
      post "/v1/objects/#{druid}/workspace/reset?workflow=accessionWF&lane-id=low",
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(ResetWorkspaceJob).to have_received(:set).with(queue: 'low')
      expect(job).to have_received(:perform_later)
        .with(druid:, version: 2, background_job_result: BackgroundJobResult, workflow: 'accessionWF')
      expect(response).to have_http_status(:created)
    end
  end
end

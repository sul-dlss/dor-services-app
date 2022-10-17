# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cleanup workspace' do
  let(:druid) { 'druid:bb222cc3333' }
  let(:job) { class_double(CleanupJob, perform_later: nil) }

  context 'when successful' do
    before do
      allow(EventFactory).to receive(:create)
      allow(CleanupJob).to receive(:set).and_return(job)
    end

    it 'returns 200' do
      delete "/v1/objects/#{druid}/workspace?workflow=accessionWF&lane-id=low",
             headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CleanupJob).to have_received(:set).with(queue: 'low')
      expect(job).to have_received(:perform_later)
        .with(druid:, background_job_result: BackgroundJobResult, workflow: 'accessionWF')
      expect(response).to have_http_status(:created)
      expect(EventFactory).to have_received(:create)
    end
  end
end

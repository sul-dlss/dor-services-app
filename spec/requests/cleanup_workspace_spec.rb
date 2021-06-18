# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cleanup workspace' do
  let(:druid) { 'druid:bb222cc3333' }
  let(:job) { class_double(CleanupJob, perform_later: nil) }

  context 'when successful' do
    before do
      allow(CleanupJob).to receive(:set).and_return(job)
    end

    it 'queus job and returns 204' do
      delete "/v1/objects/#{druid}/workspace",
             headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CleanupJob).to have_received(:set).with(queue: :default)
      byebug
      expect(job).to have_received(:perform_later)
        .with(druid: druid, background_job_result: BackgroundJobResult, workflow: 'accessionWF')
      expect(response).to have_http_status(:no_content)
    end
  end
end

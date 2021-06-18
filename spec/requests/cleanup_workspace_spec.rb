# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cleanup workspace' do
  let(:druid) { 'druid:bb222cc3333' }
  let(:job) { class_double(CleanupJob, perform_later: nil) }
  let(:result) { create(:background_job_result) }

  context 'when successful' do
    before do
      allow(EventFactory).to receive(:create)
      allow(CleanupJob).to receive(:perform_later)
      allow(BackgroundJobResult).to receive(:create).and_return(result)
    end

    it 'queus job and returns 204' do
      delete "/v1/objects/#{druid}/workspace",
             headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(CleanupJob).to have_received(:perform_later).with(druid: druid, background_job_result: result)
      expect(EventFactory).to have_received(:create).with(druid: druid,
                                                          event_type: 'cleanup-workspace received',
                                                          data: { background_job_result_id: result.id })
      expect(response).to have_http_status(:no_content)
    end
  end
end

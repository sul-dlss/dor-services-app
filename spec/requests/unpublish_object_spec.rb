# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Unpublishes an Object' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:job) { class_double(UnpublishJob, perform_later: nil) }

  before do
    allow(CocinaObjectStore).to receive(:exists!)
    allow(UnpublishJob).to receive(:set).and_return(job)
  end

  context 'when an unpublish request is successful' do
    it 'returns a 202 response' do
      post "/v1/objects/#{druid}/unpublish", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(UnpublishJob).to have_received(:set).with(queue: :publish_default)
      expect(job).to have_received(:perform_later)
        .with(druid:, background_job_result: BackgroundJobResult)
      expect(response).to have_http_status(:accepted)
    end
  end
end

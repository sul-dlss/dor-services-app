# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnpublishJob, type: :job do
  subject(:perform) do
    described_class.perform_now(druid:, background_job_result: result)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }

  before do
    allow(result).to receive(:processing!)
    allow(EventFactory).to receive(:create)
  end

  context 'with no errors' do
    before do
      allow(UnpublishService).to receive(:unpublish)
      allow(LogSuccessJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CleanupJob do
  subject(:perform) do
    described_class.perform_now(druid:, background_job_result: result)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }

  before do
    # allow(CocinaObjectStore).to receive(:find).with(druid).and_return(item)
    allow(result).to receive(:processing!)
    allow(EventFactory).to receive(:create)
  end

  context 'with no errors' do
    before do
      allow(CleanupService).to receive(:cleanup_by_druid)
      allow(LogSuccessJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the CleanupService' do
      expect(CleanupService).to have_received(:cleanup_by_druid).with(druid).once
    end

    it 'marks the job as complete' do
      expect(EventFactory).to have_received(:create)

      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'reset-workspace')
    end
  end

  context 'with errors' do
    before do
      allow(CleanupService).to receive(:cleanup_by_druid).and_raise(Errno::ENOENT)
      allow(LogFailureJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as complete' do
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid:,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'reset-workspace',
              output: { errors: [{ detail: 'No such file or directory', title: 'Unable to cleanup workspace' }] })
    end
  end
end

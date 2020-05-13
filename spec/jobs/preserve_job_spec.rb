# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreserveJob, type: :job do
  include ActiveJob::TestHelper

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:item) { instance_double(Dor::Item, current_version: '7') }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(item)
    allow(result).to receive(:processing!)
    allow(Honeybadger).to receive(:notify)
    allow(Honeybadger).to receive(:context)
  end

  context 'with no errors' do
    subject(:perform) { described_class.perform_now(druid: druid, background_job_result: result) }

    before do
      allow(SdrIngestService).to receive(:transfer)
      allow(StartPreservationWorkflowJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the SdrIngestService' do
      expect(SdrIngestService).to have_received(:transfer).with(item).once
    end

    it 'marks the job as complete' do
      expect(StartPreservationWorkflowJob).to have_received(:perform_later)
    end
  end

  context 'with errors returned by SdrIngestService' do
    let(:error_message) { 'something broke' }

    before do
      allow(SdrIngestService).to receive(:transfer).and_raise(error_message)
      allow(LogFailureJob).to receive(:perform_later)
    end

    it 'marks the job as errored' do
      perform_enqueued_jobs do
        described_class.perform_now(druid: druid, background_job_result: result)
      end
      expect(result).to have_received(:processing!).once
      expect(SdrIngestService).to have_received(:transfer).with(item).exactly(5).times
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid: druid,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'sdr-ingest-transfer',
              output: { errors: [{ detail: error_message, title: 'Preservation error' }] })
      expect(Honeybadger).to have_received(:context).with(background_job_result_id: result.id)
    end
  end
end

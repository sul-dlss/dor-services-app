# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishJob do
  subject(:perform) do
    described_class.perform_now(druid:, background_job_result: result, workflow:)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:item) { instance_double(Cocina::Models::DRO, admin_policy?: false) }
  let(:workflow) { 'accessionWF' }
  let(:valid) { true }
  let(:invalid_filenames) { [] }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(item)
    allow(result).to receive(:processing!)
    allow(EventFactory).to receive(:create)
  end

  context 'with no errors' do
    before do
      allow(Publish::MetadataTransferService).to receive(:publish)
      allow(LogSuccessJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the Publish::MetadataTransferService' do
      expect(Publish::MetadataTransferService).to have_received(:publish).with(item, workflow:).once
    end

    it 'marks the job as complete' do
      expect(EventFactory).to have_received(:create)

      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'publish')
    end

    context 'when log_success is set to false' do
      subject(:perform) do
        described_class.perform_now(druid:, background_job_result: result, workflow:, log_success: false)
      end

      it 'does not mark the job as complete' do
        expect(EventFactory).to have_received(:create)

        expect(LogSuccessJob).not_to have_received(:perform_later)
          .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'publish')
      end
    end

    context 'when log_success is set to true' do
      subject(:perform) do
        described_class.perform_now(druid:, background_job_result: result, workflow:, log_success: true)
      end

      it 'mark the job as complete' do
        expect(EventFactory).to have_received(:create)

        expect(LogSuccessJob).to have_received(:perform_later)
          .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'publish')
      end
    end
  end

  context 'when an AdminPolicy' do
    let(:item) { instance_double(Cocina::Models::AdminPolicy, admin_policy?: true) }

    before do
      allow(LogFailureJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as a failure' do
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid:, background_job_result: result, workflow: 'accessionWF', workflow_process: 'publish', output: Hash)
    end
  end
end

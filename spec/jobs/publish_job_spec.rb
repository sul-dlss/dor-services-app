# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishJob, type: :job do
  subject(:perform) do
    described_class.perform_now(druid: druid, background_job_result: result, workflow: workflow)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:item) { instance_double(Cocina::Models::DRO) }
  let(:workflow) { 'accessionWF' }
  let(:valid) { true }
  let(:invalid_filenames) { [] }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(item)
    allow(result).to receive(:processing!)
    allow(EventFactory).to receive(:create)
    allow(Cocina::Mapper).to receive(:build)
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
      expect(Publish::MetadataTransferService).to have_received(:publish).with(item).once
    end

    it 'marks the job as complete' do
      expect(EventFactory).to have_received(:create)

      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid: druid, background_job_result: result, workflow: 'accessionWF', workflow_process: 'publish')
    end
  end

  context 'when fails dark validation', skip: true do
    let(:valid) { false }
    let(:invalid_filenames) { ['foo.txt', 'bar.txt'] }

    before do
      allow(LogFailureJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'marks the job as complete' do
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid: druid,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'publish',
              output: { errors: [{ detail: 'Not all files have dark access and/or are unshelved when item access is dark: ["foo.txt", "bar.txt"]', title: 'Access mismatch' }] })
    end
  end
end

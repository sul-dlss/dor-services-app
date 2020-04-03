# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishJob, type: :job do
  subject(:perform) do
    described_class.perform_now(druid: druid, background_job_result: result, workflow: workflow)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:item) { instance_double(Dor::Item) }
  let(:workflow) { 'accessionWF' }
  let(:validator) { instance_double(ValidateDarkService, valid?: valid, invalid_filenames: invalid_filenames) }
  let(:valid) { true }
  let(:invalid_filenames) { [] }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(item)
    allow(result).to receive(:processing!)
    allow(EventFactory).to receive(:create)
    allow(Cocina::Mapper).to receive(:build)
    allow(ValidateDarkService).to receive(:new).and_return(validator)
  end

  context 'with no errors' do
    before do
      allow(PublishMetadataService).to receive(:publish)
      allow(LogSuccessJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the PublishMetadataService' do
      expect(PublishMetadataService).to have_received(:publish).with(item).once
    end

    it 'marks the job as complete' do
      expect(EventFactory).to have_received(:create)

      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid: druid, background_job_result: result, workflow: 'accessionWF', workflow_process: 'publish-complete')
    end
  end

  context 'with errors returned by PublishMetadataService' do
    let(:error_message) { "DublinCoreService#ng_xml produced incorrect xml (no children):\n<xml/>" }

    before do
      allow(PublishMetadataService).to receive(:publish).and_raise(Dor::DataError, error_message)
      allow(LogFailureJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the PublishMetadataService' do
      expect(PublishMetadataService).to have_received(:publish).with(item).once
    end

    it 'marks the job as complete' do
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid: druid,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'publish-complete',
              output: { errors: [{ detail: error_message, title: 'Data error' }] })
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
              workflow_process: 'publish-complete',
              output: { errors: [{ detail: 'Not all files have dark access and/or are unshelved when item access is dark: ["foo.txt", "bar.txt"]', title: 'Access mismatch' }] })
    end
  end
end

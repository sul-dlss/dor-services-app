# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelveJob, type: :job do
  subject(:perform) { described_class.perform_now(druid: druid, background_job_result: result) }

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:item) { instance_double(Dor::Item) }
  let(:validator) { instance_double(Cocina::ValidateDarkService, valid?: valid, invalid_filenames: invalid_filenames) }
  let(:valid) { true }
  let(:invalid_filenames) { [] }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(item)
    allow(result).to receive(:processing!)
    allow(EventFactory).to receive(:create)
    allow(Cocina::Mapper).to receive(:build)
    allow(Cocina::ValidateDarkService).to receive(:new).and_return(validator)
  end

  context 'with no errors' do
    before do
      allow(ShelvingService).to receive(:shelve)
      allow(LogSuccessJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the ShelvingService' do
      expect(ShelvingService).to have_received(:shelve).with(item).once
    end

    it 'marks the job as complete' do
      expect(EventFactory).to have_received(:create)
      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid: druid,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'shelve')
    end
  end

  context 'with errors returned by ShelvingService' do
    let(:error_message) { "file isn't where we looked" }

    before do
      allow(ShelvingService).to receive(:shelve).and_raise(ShelvableFilesStager::FileNotFound, error_message)
      allow(LogFailureJob).to receive(:perform_later)
    end

    it 'marks the job as errored' do
      perform
      expect(result).to have_received(:processing!).once
      expect(ShelvingService).to have_received(:shelve).with(item).once
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid: druid,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'shelve',
              output: { errors: [{ detail: error_message, title: 'Unable to shelve files' }] })
    end
  end

  context 'when fails dark validation', skip: true do
    let(:valid) { false }
    let(:invalid_filenames) { ['foo.txt', 'bar.txt'] }

    before do
      allow(LogFailureJob).to receive(:perform_later)
    end

    it 'marks the job as errored' do
      perform
      expect(result).to have_received(:processing!).once
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid: druid,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'shelve',
              output: { errors: [{ detail: 'Not all files have dark access and/or are unshelved when item access is dark: ["foo.txt", "bar.txt"]', title: 'Access mismatch' }] })
    end
  end
end

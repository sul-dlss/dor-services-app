# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelveJob do
  subject(:perform) { described_class.perform_now(druid:, background_job_result: result) }

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:cocina_object) { instance_double(Cocina::Models::DRO) }
  let(:valid) { true }
  let(:invalid_filenames) { [] }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
    allow(result).to receive(:processing!)
    allow(EventFactory).to receive(:create)
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
      expect(ShelvingService).to have_received(:shelve).with(cocina_object).once
    end

    it 'marks the job as complete' do
      expect(EventFactory).to have_received(:create)
      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid:,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'shelve')
    end
  end

  context 'with errors returned by ShelvingService' do
    let(:error_message) { "file isn't where we looked" }

    before do
      allow(ShelvingService).to receive(:shelve).and_raise(LegacyShelvableFilesStager::FileNotFound, error_message)
      allow(LogFailureJob).to receive(:perform_later)
    end

    it 'marks the job as errored' do
      perform
      expect(result).to have_received(:processing!).once
      expect(ShelvingService).to have_received(:shelve).with(cocina_object).once
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid:,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'shelve',
              output: { errors: [{ detail: error_message, title: 'Unable to shelve files' }] })
    end
  end

  context 'when publish_shelve feature flag is enabled' do
    before do
      allow(Settings.enabled_features).to receive(:publish_shelve).and_return(true)
      allow(ShelvingService).to receive(:shelve)
      allow(LogSuccessJob).to receive(:perform_later)
    end

    context 'when not a WAS crawl' do
      before do
        allow(WasService).to receive(:crawl?).with(druid:).and_return(false)
      end

      it 'skips shelving' do
        perform
        expect(ShelvingService).not_to have_received(:shelve)
        expect(LogSuccessJob).to have_received(:perform_later)
          .with(druid:,
                background_job_result: result,
                workflow: 'accessionWF',
                workflow_process: 'shelve')
      end
    end

    context 'when a WAS crawl' do
      before do
        allow(WasService).to receive(:crawl?).with(druid:).and_return(true)
      end

      it 'performs shelving' do
        perform
        expect(ShelvingService).to have_received(:shelve).with(cocina_object).once
        expect(LogSuccessJob).to have_received(:perform_later)
          .with(druid:,
                background_job_result: result,
                workflow: 'accessionWF',
                workflow_process: 'shelve')
      end
    end
  end
end

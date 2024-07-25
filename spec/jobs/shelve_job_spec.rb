# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelveJob do
  subject(:perform) { described_class.perform_now(druid:, background_job_result: result) }

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:cocina_object) { instance_double(Cocina::Models::DRO) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
    allow(result).to receive(:processing!)
    allow(EventFactory).to receive(:create)
    allow(WasShelvingService).to receive(:shelve)
    allow(LogSuccessJob).to receive(:perform_later)
  end

  context 'when not a WAS crawl' do
    before do
      allow(WasService).to receive(:crawl?).with(druid:).and_return(false)
    end

    it 'skips shelving' do
      perform
      expect(WasShelvingService).not_to have_received(:shelve)
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
      expect(WasShelvingService).to have_received(:shelve).with(cocina_object).once
      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid:,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'shelve')
    end
  end

  context 'when there is an error' do
    before do
      allow(WasService).to receive(:crawl?).with(druid:).and_return(true)
      allow(WasShelvingService).to receive(:shelve).and_raise(StandardError)
      allow(LogFailureJob).to receive(:perform_later)
      allow(Honeybadger).to receive(:notify)
    end

    it 'raises and notifies Honeybadger' do
      perform
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid:,
              background_job_result: result,
              workflow: 'accessionWF',
              workflow_process: 'shelve',
              output: { errors: [{ detail: 'StandardError', title: 'Unable to shelve web archive files' }] })
      expect(Honeybadger).to have_received(:notify)
    end
  end
end

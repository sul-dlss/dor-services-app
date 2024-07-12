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

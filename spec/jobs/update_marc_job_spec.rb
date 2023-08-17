# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateMarcJob do
  subject(:perform) do
    described_class.perform_now(druid:, background_job_result: result)
  end

  let(:result) { create(:background_job_result) }
  let(:cocina_object) { build(:dro, id: druid) }
  let(:druid) { 'druid:mx123qw2323' }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
    allow(result).to receive(:processing!)
  end

  context 'with no errors' do
    before do
      allow(Catalog::UpdateMarc856RecordService).to receive(:update)
      allow(LogSuccessJob).to receive(:perform_later)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the UpdateMarc856RecordService' do
      expect(Catalog::UpdateMarc856RecordService).to have_received(:update).once
    end

    it 'marks the job as complete' do
      expect(LogSuccessJob).to have_received(:perform_later)
        .with(druid:, background_job_result: result, workflow: 'releaseWF', workflow_process: 'update-marc')
    end
  end

  context 'with errors' do
    before do
      allow(Catalog::UpdateMarc856RecordService).to receive(:update).and_raise(StandardError, 'FOLIO update not completed.')
      allow(LogFailureJob).to receive(:perform_later)
      perform
    end

    it 'logs failure' do
      expect(LogFailureJob).to have_received(:perform_later)
        .with(druid:,
              background_job_result: result,
              workflow: 'releaseWF',
              workflow_process: 'update-marc',
              output: { errors: [{ title: 'Update MARC error', detail: 'FOLIO update not completed.' }] })
    end
  end
end

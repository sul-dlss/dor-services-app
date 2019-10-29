# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreserveJob, type: :job do
  subject(:perform) { described_class.perform_now(druid: druid, background_job_result: result) }

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:item) { instance_double(Dor::Item) }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(item)
    allow(result).to receive(:processing!)
  end

  context 'with no errors' do
    before do
      allow(SdrIngestService).to receive(:transfer)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the SdrIngestService' do
      expect(SdrIngestService).to have_received(:transfer).with(item).once
    end

    it 'marks the job as complete' do
      expect(result).to be_complete
    end

    it 'has no output' do
      expect(result.output).to be_blank
    end
  end

  context 'with errors returned by SdrIngestService' do
    let(:error_message) { 'something broke' }

    before do
      allow(SdrIngestService).to receive(:transfer).and_raise(error_message)
    end

    it 'marks the job as errored' do
      expect { perform }.to raise_error(error_message)
      expect(result).to have_received(:processing!).once
      expect(SdrIngestService).to have_received(:transfer).with(item).once
      expect(result).to be_complete
      expect(result.output[:errors]).to eq [{ 'detail' => error_message, 'title' => 'Preservation error' }]
    end
  end
end

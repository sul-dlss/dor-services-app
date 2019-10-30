# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelveJob, type: :job do
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
      allow(ShelvingService).to receive(:shelve)
      perform
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the ShelvingService' do
      expect(ShelvingService).to have_received(:shelve).with(item).once
    end

    it 'marks the job as complete' do
      expect(result).to be_complete
    end

    it 'has no output' do
      expect(result.output).to be_blank
    end
  end

  context 'with errors returned by ShelvingService' do
    let(:error_message) { "file isn't where we looked" }

    before do
      allow(ShelvingService).to receive(:shelve).and_raise(ShelvingService::ContentDirNotFoundError, error_message)
    end

    it 'marks the job as errored' do
      perform
      expect(result).to have_received(:processing!).once
      expect(ShelvingService).to have_received(:shelve).with(item).once
      expect(result).to be_complete
      expect(result.output[:errors]).to eq [{ 'detail' => error_message, 'title' => 'Content directory not found' }]
    end
  end
end

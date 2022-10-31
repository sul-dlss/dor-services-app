# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LogSuccessJob do
  subject(:perform) do
    described_class.perform_now(druid:,
                                background_job_result: result,
                                workflow:,
                                workflow_process:)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:workflow_process) { 'shelve' }
  let(:client) { instance_double(Dor::Workflow::Client, update_status: nil) }

  before do
    allow(result).to receive(:complete!)
    allow(LogFailureJob).to receive(:perform_later)
    allow(WorkflowClientFactory).to receive(:build).and_return(client)
  end

  context 'when workflow is provided' do
    let(:workflow) { 'accessionWF' }

    it 'marks the job as complete' do
      perform
      expect(result).to have_received(:complete!).once
      expect(client).to have_received(:update_status)
    end
  end

  context 'when workflow is not provided' do
    let(:workflow) { nil }

    it 'marks the job as complete' do
      perform
      expect(result).to have_received(:complete!).once
      expect(client).not_to have_received(:update_status)
    end
  end
end

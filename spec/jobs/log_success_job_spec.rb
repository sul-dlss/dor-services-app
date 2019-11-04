# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LogSuccessJob, type: :job do
  subject(:perform) do
    described_class.perform_now(druid: druid,
                                background_job_result: result,
                                workflow_process: workflow_process)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:workflow_process) { 'shelve' }

  before do
    allow(result).to receive(:complete!)
    allow(LogFailureJob).to receive(:perform_later)
    allow(Dor::Config.workflow.client).to receive(:update_status)
  end

  it 'marks the job as errored' do
    perform
    expect(result).to have_received(:complete!).once
    expect(Dor::Config.workflow.client).to have_received(:update_status)
  end
end

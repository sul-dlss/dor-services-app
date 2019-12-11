# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StartPreservationWorkflowJob, type: :job do
  subject(:perform) do
    described_class.perform_now(druid: druid,
                                background_job_result: result)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }

  before do
    allow(result).to receive(:complete!)
    allow(LogFailureJob).to receive(:perform_later)
    allow(Dor::Config.workflow.client).to receive(:create_workflow_by_name)
  end

  it 'marks the job as errored' do
    perform
    expect(result).to have_received(:complete!).once
    expect(Dor::Config.workflow.client).to have_received(:create_workflow_by_name)
      .with(druid, 'preservationIngestWF')
  end
end

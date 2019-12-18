# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StartPreservationWorkflowJob, type: :job do
  subject(:perform) do
    described_class.perform_now(druid: druid,
                                version: '7',
                                background_job_result: result)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }

  before do
    allow(LogSuccessJob).to receive(:perform_later)
    allow(Dor::Config.workflow.client).to receive(:create_workflow_by_name)
  end

  it 'marks the job as success' do
    perform
    expect(Dor::Config.workflow.client).to have_received(:create_workflow_by_name)
      .with(druid, 'preservationIngestWF', version: '7')
    expect(LogSuccessJob).to have_received(:perform_later)
      .with(
        druid: druid,
        background_job_result: result,
        workflow: 'accessionWF',
        workflow_process: 'preservation-ingest-initiated'
      )
  end
end

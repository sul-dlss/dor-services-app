# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StartPreservationWorkflowJob do
  subject(:perform) do
    described_class.perform_now(druid:,
                                version: '7',
                                background_job_result: result)
  end

  let(:druid) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'default') }
  let(:client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil, process:) }

  before do
    allow(LogSuccessJob).to receive(:perform_later)
    allow(WorkflowClientFactory).to receive(:build).and_return(client)
  end

  it 'marks the job as success' do
    perform
    expect(client).to have_received(:create_workflow_by_name)
      .with(druid, 'preservationIngestWF', version: '7', lane_id: 'default')
    expect(LogSuccessJob).to have_received(:perform_later)
      .with(
        druid:,
        background_job_result: result,
        workflow: 'accessionWF',
        workflow_process: 'sdr-ingest-transfer'
      )
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowService do
  let(:druid) { 'druid:bb033gt0615' }
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '#workflow?' do
    let(:workflows) do
      instance_double(Dor::Workflow::Response::Workflows, workflows: [accessioning_workflow, was_workflow])
    end
    let(:was_workflow) { instance_double(Dor::Workflow::Response::Workflow, workflow_name: 'wasCrawlPreassemblyWF') }
    let(:accessioning_workflow) { instance_double(Dor::Workflow::Response::Workflow, workflow_name: 'accessioningWF') }

    before do
      allow(workflow_client).to receive(:all_workflows).with(pid: druid).and_return(workflows)
    end

    context 'when the workflow exists' do
      it 'returns true' do
        expect(described_class.workflow?(druid:, workflow_name: 'wasCrawlPreassemblyWF')).to be true
        expect(workflow_client).to have_received(:all_workflows).with(pid: druid)
      end
    end

    context 'when the workflow does not exist' do
      it 'returns false' do
        expect(described_class.workflow?(druid:, workflow_name: 'anotherWF')).to be false
      end
    end
  end

  describe '#create' do
    let(:workflow_name) { 'wasCrawlPreassemblyWF' }
    let(:version) { 1 }
    let(:context) { { 'key' => 'value' } }
    let(:lane_id) { 'low' }

    before do
      allow(workflow_client).to receive(:create_workflow_by_name).with(druid, workflow_name, version:, context:,
                                                                                             lane_id:)
    end

    it 'creates a workflow' do
      described_class.create(druid:, workflow_name:, version:, context:, lane_id:)
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, workflow_name, version:, context:,
                                                                                                    lane_id:)
    end
  end

  describe '#delete' do
    let(:workflow_name) { 'wasCrawlPreassemblyWF' }
    let(:version) { 1 }

    before do
      allow(workflow_client).to receive(:delete_workflow).with(druid:, workflow: workflow_name, version:)
    end

    it 'deletes a workflow' do
      described_class.delete(druid:, workflow_name:, version:)
      expect(workflow_client).to have_received(:delete_workflow).with(druid:, workflow: workflow_name, version:)
    end
  end

  describe '#delete_all' do
    before do
      allow(workflow_client).to receive(:delete_all_workflows).with(pid: druid)
    end

    it 'deletes all workflows' do
      described_class.delete_all(druid:)
      expect(workflow_client).to have_received(:delete_all_workflows).with(pid: druid)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowService do
  let(:druid) { 'druid:bb033gt0615' }
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '#workflows' do
    let(:workflows_response) { instance_double(Dor::Workflow::Response::Workflows, workflows: workflows) }
    let(:workflows) { [instance_double(Dor::Workflow::Response::Workflow)] }

    before do
      allow(workflow_client).to receive(:all_workflows).with(pid: druid).and_return(workflows_response)
    end

    it 'returns workflows' do
      expect(described_class.workflows(druid:)).to eq workflows
      expect(workflow_client).to have_received(:all_workflows).with(pid: druid)
    end
  end

  describe '#workflows_xml' do
    let(:workflows_response) { instance_double(Dor::Workflow::Response::Workflows, xml: workflows_xml) }
    let(:workflows_xml) { instance_double(Nokogiri::XML::Document) }

    before do
      allow(workflow_client).to receive(:all_workflows).with(pid: druid).and_return(workflows_response)
    end

    it 'returns workflows xml' do
      expect(described_class.workflows_xml(druid:)).to eq workflows_xml
      expect(workflow_client).to have_received(:all_workflows).with(pid: druid)
    end
  end

  describe '#workflow' do
    context 'when local workflow feature is enabled' do
      subject(:workflow) { described_class.workflow(druid:, workflow_name: 'accessionWF') }

      before do
        allow(Settings.enabled_features).to receive(:local_wf).and_return(true)
      end

      context 'when there are no steps' do
        it 'returns an empty workflow' do
          expect(workflow).to be_a(Dor::Services::Response::Workflow)
          expect(workflow.workflow_name).to eq 'accessionWF'
          expect(workflow.pid).to eq druid
          expect(workflow.empty?).to be true
        end
      end

      context 'when there are workflow steps' do
        before do
          create(:workflow_step, druid:, workflow: 'accessionWF', version: 1, status: 'completed')
          create(:workflow_step, druid:, workflow: 'accessionWF', version: 1, status: 'completed',
                                 process: 'end-accession')
        end

        it 'returns a workflow' do
          expect(workflow).to be_a(Dor::Services::Response::Workflow)
          expect(workflow.empty?).to be false
          process = workflow.process_for_recent_version(name: 'end-accession')
          expect(process.name).to eq 'end-accession'
          expect(process.status).to eq 'completed'
        end
      end
    end

    context 'when local workflow feature is not enabled' do
      let(:was_workflow) { instance_double(Dor::Workflow::Response::Workflow, workflow_name: 'wasCrawlPreassemblyWF') }

      before do
        allow(workflow_client).to receive(:workflow)
          .with(pid: druid, workflow_name: 'wasCrawlPreassemblyWF').and_return(was_workflow)
      end

      it 'returns the workflow' do
        expect(described_class.workflow(druid:, workflow_name: 'wasCrawlPreassemblyWF')).to eq was_workflow
      end
    end
  end

  describe '#workflow?' do
    let(:was_workflow) { instance_double(Dor::Workflow::Response::Workflow, workflow_name: 'wasCrawlPreassemblyWF', empty?: empty) }

    before do
      allow(workflow_client).to receive(:workflow)
        .with(pid: druid, workflow_name: 'wasCrawlPreassemblyWF').and_return(was_workflow)
    end

    context 'when the workflow exists' do
      let(:empty) { false }

      it 'returns true' do
        expect(described_class.workflow?(druid:, workflow_name: 'wasCrawlPreassemblyWF')).to be true
      end
    end

    context 'when the workflow does not exist' do
      let(:empty) { true }

      it 'returns false' do
        expect(described_class.workflow?(druid:, workflow_name: 'wasCrawlPreassemblyWF')).to be false
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

  describe '#skip_all' do
    before do
      allow(workflow_client).to receive(:skip_all)
    end

    it 'skips all steps in a workflow' do
      described_class.skip_all(druid:, workflow_name: 'wasCrawlPreassemblyWF', note: 'Skipping all steps')
      expect(workflow_client).to have_received(:skip_all).with(druid:, workflow: 'wasCrawlPreassemblyWF',
                                                               note: 'Skipping all steps')
    end
  end
end

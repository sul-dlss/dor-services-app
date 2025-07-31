# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::Service do
  let(:druid) { 'druid:bb033gt0615' }

  describe '#workflows' do
    subject(:workflows) { described_class.workflows(druid:) }

    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <workflow id="accessionWF" objectId="druid:bb033gt0615">
          <process version="1" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2025-07-22T21:35:36+00:00" context="{&quot;requireOCR&quot;:true,&quot;requireTranscript&quot;:true}" status="waiting" name="start-accession"/>
        </workflow>
      XML
    end

    before do
      create(:workflow_step, :with_ocr_context, druid:, updated_at: '2025-07-22T21:35:36+00:00', status: 'waiting')
    end

    it 'returns workflows' do
      expect(workflows).to be_a(Array)
      expect(workflows.size).to eq 1
      expect(workflows.first).to be_a(Dor::Services::Response::Workflow)
      expect(workflows.first.xml).to be_equivalent_to xml
    end
  end

  describe '#workflows_xml' do
    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <workflows objectId="druid:bb033gt0615">
          <workflow id="accessionWF" objectId="druid:bb033gt0615">
           <process version="2" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2025-07-22T21:35:36+00:00" context="{&quot;requireOCR&quot;:true,&quot;requireTranscript&quot;:true}" status="waiting" name="start-accession"/>
           <process version="1" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2025-07-22T21:35:36+00:00" context="{&quot;requireOCR&quot;:true,&quot;requireTranscript&quot;:true}" status="waiting" name="start-accession"/>
         </workflow>
         <workflow id="wasCrawlPreassemblyWF" objectId="druid:bb033gt0615">
           <process version="1" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2025-07-22T21:35:36+00:00" context="{&quot;requireOCR&quot;:true,&quot;requireTranscript&quot;:true}" status="waiting" name="start"/>
         </workflow>
        </workflows>
      XML
    end

    before do
      create(:workflow_step, :with_ocr_context, druid:, updated_at: '2025-07-22T21:35:36+00:00', version: 2)
      create(:workflow_step, :with_ocr_context, druid:, updated_at: '2025-07-22T21:35:36+00:00', status: 'waiting')
      create(:workflow_step, druid:, updated_at: '2025-07-22T21:35:36+00:00', process: 'start',
                             workflow: 'wasCrawlPreassemblyWF')
    end

    it 'returns workflows XML' do
      expect(described_class.workflows_xml(druid:)).to be_equivalent_to xml
    end
  end

  describe '#workflow' do
    subject(:workflow) { described_class.workflow(druid:, workflow_name: 'accessionWF') }

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

  describe '#workflow?' do
    before do
      create(:workflow_step, druid:, workflow: 'accessionWF', version: 1, status: 'completed')
      create(:workflow_step, druid:, workflow: 'accessionWF', version: 1, status: 'completed',
                             process: 'end-accession')
    end

    context 'when the workflow exists' do
      it 'returns true' do
        expect(described_class.workflow?(druid:, workflow_name: 'accessionWF')).to be true
      end
    end

    context 'when the workflow does not exist' do
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
      allow(Workflow::NextStepService).to receive(:enqueue_next_steps)
    end

    it 'creates a workflow' do
      expect do
        described_class.create(druid:, workflow_name:, version:, context:, lane_id:)
      end.to change(WorkflowStep, :count).by(3)
      expect(Workflow::NextStepService).to have_received(:enqueue_next_steps).once
    end
  end

  describe '#delete' do
    let(:workflow_name) { 'accessionWF' }
    let(:version) { 1 }

    let!(:step) { create(:workflow_step, druid:, workflow: workflow_name, version: 1) }

    before do
      # Different version
      create(:workflow_step, druid:, workflow: workflow_name, version: 2)
    end

    it 'deletes the workflow steps for the specified version' do
      expect { described_class.delete(druid:, workflow_name:, version:) }.to change(WorkflowStep, :count).by(-1)
      expect(WorkflowStep.exists?(step.id)).to be false
    end
  end

  describe '#delete_all' do
    let!(:step) { create(:workflow_step, druid:, version: 1) }
    let!(:step_with_different_version) { create(:workflow_step, druid:, version: 2) }
    let!(:step_with_different_workflow) do
      create(:workflow_step, druid:, workflow: 'wasCrawlPreassemblyWF', version: 1, process: 'start')
    end
    let!(:step_with_different_druid) { create(:workflow_step, druid: 'druid:jp974nv2747', version: 1) }

    it 'deletes all workflow steps for the druid' do
      expect { described_class.delete_all(druid:) }.to change(WorkflowStep, :count).by(-3)
      expect(WorkflowStep.exists?(step.id)).to be false
      expect(WorkflowStep.exists?(step_with_different_version.id)).to be false
      expect(WorkflowStep.exists?(step_with_different_workflow.id)).to be false
      expect(WorkflowStep.exists?(step_with_different_druid.id)).to be true # Different druid should not be deleted
    end
  end

  describe '#skip_all' do
    let!(:step) { create(:workflow_step, druid:, status: 'waiting', active_version: true, version: 2) }
    let!(:another_step) do
      create(:workflow_step, process: 'end-accession', druid:, status: 'waiting', active_version: true, version: 2)
    end
    let!(:step_not_current_version) do
      create(:workflow_step, druid:, status: 'waiting', active_version: false, version: 1)
    end
    let!(:step_with_different_workflow) do
      create(:workflow_step, druid:, workflow: 'wasCrawlPreassemblyWF', process: 'start', status: 'waiting',
                             active_version: true, version: 2)
    end

    it 'skips all steps in a workflow' do
      expect { described_class.skip_all(druid:, workflow_name: 'accessionWF', note: 'Skipping all steps') }
        .to change { step.reload.status }
        .from('waiting').to('skipped')
        .and change(step, :note)
        .to('Skipping all steps')
        .and change { another_step.reload.status }
        .from('waiting').to('skipped')
        .and(not_change { step_not_current_version.reload.status })
        .and(not_change { step_with_different_workflow.reload.status })
    end
  end
end

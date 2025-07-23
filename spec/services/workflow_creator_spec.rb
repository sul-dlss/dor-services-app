# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowCreator do
  let(:druid) { 'druid:bb123bb1234' }
  let(:xml) do
    workflow_template = WorkflowTemplateLoader.load_as_xml('accessionWF')
    WorkflowTransformer.initial_workflow(workflow_template)
  end
  let(:wf_parser) do
    InitialWorkflowParser.new(xml)
  end

  before do
    allow(QueueService).to receive(:enqueue)
  end

  describe '#create_workflow_steps' do
    subject(:create_workflow_steps) { wf_creator.create_workflow_steps }

    context 'without context' do
      let(:wf_creator) do
        described_class.new(
          workflow_id: wf_parser.workflow_id,
          processes: wf_parser.processes,
          version: Version.new(druid:, version: 1)
        )
      end

      it 'creates a WorkflowStep for each process' do
        expect do
          create_workflow_steps
        end.to change(WorkflowStep, :count).by(ACCESSION_WF_STEP_COUNT)
        expect(WorkflowStep.last.druid).to eq druid
        first_step = WorkflowStep.find_by(druid:, process: 'start-accession')
        expect(QueueService).to have_received(:enqueue).with(first_step)
      end

      context 'when workflow steps already exists' do
        before do
          wf_creator.create_workflow_steps
        end

        it 'replaces them' do
          expect do
            create_workflow_steps
          end.not_to change(WorkflowStep, :count)
          first_step = WorkflowStep.find_by(druid:, process: 'start-accession')
          expect(QueueService).to have_received(:enqueue).with(first_step)
        end
      end
    end

    context 'with context' do
      let(:wf_creator) do
        described_class.new(
          workflow_id: wf_parser.workflow_id,
          processes: wf_parser.processes,
          version: Version.new(druid:, version: 1, context: { requireOCR: true, requireTranscript: true })
        )
      end

      it 'creates a WorkflowStep for each process, along with version context' do
        expect do
          create_workflow_steps
        end.to change(WorkflowStep, :count).by(ACCESSION_WF_STEP_COUNT)
        expect(WorkflowStep.last.druid).to eq druid
        first_step = WorkflowStep.find_by(druid:, process: 'start-accession')
        expect(QueueService).to have_received(:enqueue).with(first_step)
        # returns context as json
        expect(VersionContext.find_by(druid:,
                                      version: 1).values).to eq({
                                                                  'requireOCR' => true, 'requireTranscript' => true
                                                                })
      end
    end
  end
end

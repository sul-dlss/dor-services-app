# frozen_string_literal: true

require 'rails_helper'

# These specs are adapted from the specs for Dor::Services::Response::Workflow.
RSpec.describe Workflow::WorkflowResponse do
  subject(:workflow_response) { described_class.new(druid:, workflow_name:, steps:) }

  let(:druid) { 'druid:mw971zk1113' }
  let(:workflow_name) { 'assemblyWF' }
  let(:steps) { [] }

  describe '#pid' do
    subject { workflow_response.pid }

    it { is_expected.to eq 'druid:mw971zk1113' }
  end

  describe '#workflow_name' do
    subject { workflow_response.workflow_name }

    it { is_expected.to eq 'assemblyWF' }
  end

  describe '#complete?' do
    subject { workflow_response.complete? }

    context 'when all steps are complete' do
      let(:xml) do
        <<~XML
          <workflow repository="dor" objectId="druid:mw971zk1113" id="assemblyWF">
            <process version="1" laneId="default" elapsed="0.0" attempts="1" datetime="2013-02-18T14:40:25-0800" status="completed" name="start-assembly"/>
            <process version="1" laneId="default" elapsed="0.509" attempts="1" datetime="2013-02-18T14:42:24-0800" status="completed" name="jp2-create"/>
          </workflow>
        XML
      end

      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create')
        ]
      end

      it { is_expected.to be true }
    end

    context 'when some steps are not complete' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
          build(:workflow_step, druid:, workflow: workflow_name, process: 'jp2-create')
        ]
      end

      it { is_expected.to be false }
    end
  end

  describe '#complete_for?' do
    let(:steps) do
      [
        build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
        build(:workflow_step, druid:, workflow: workflow_name, process: 'jp2-create'),
        build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly', version: 2),
        build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create', version: 2)
      ]
    end

    context 'when all steps are complete' do
      it 'returns true' do
        expect(workflow_response.complete_for?(version: 2)).to be true
      end
    end

    context 'when some steps are not complete' do
      it 'returns false' do
        expect(workflow_response.complete_for?(version: 1)).to be false
      end
    end
  end

  describe '#active_for?' do
    subject { workflow_response.active_for?(version: 2) }

    context 'when the workflow has not been instantiated for the given version' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create')
        ]
      end

      it { is_expected.to be false }
    end

    context 'when the workflow has been instantiated for the given version' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create'),
          build(:workflow_step, druid:, workflow: workflow_name, process: 'jp2-create', version: 2)
        ]
      end

      it { is_expected.to be true }
    end
  end

  describe '#empty?' do
    subject { workflow_response.empty? }

    context 'when there are steps' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly')
        ]
      end

      it { is_expected.to be false }
    end

    context 'when there are no steps' do
      it { is_expected.to be true }
    end
  end

  describe '#error_count' do
    subject(:error_count) { workflow_response.error_count }

    context 'when errors present in latest version' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create'),
          build(:workflow_step, :error, druid:, workflow: workflow_name, process: 'jp2-create', version: 2)
        ]
      end

      it { is_expected.to eq(1) }
    end

    context 'when no errors present in latest version' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create')
        ]
      end

      it { is_expected.to eq(0) }
    end

    context 'when errors in earlier versions' do
      let(:steps) do
        [
          build(:workflow_step, :error, druid:, workflow: workflow_name, process: 'start-assembly', version: 1),
          build(:workflow_step, :error, druid:, workflow: workflow_name, process: 'jp2-create', version: 1),
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create', version: 2)
        ]
      end

      it { is_expected.to eq(0) }
    end
  end

  describe '#process_for_recent_version' do
    subject(:process) { workflow_response.process_for_recent_version(name: 'jp2-create') }

    context 'when the workflow has not been instantiated for the given version' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create')
        ]
      end

      it 'returns a process' do
        expect(process).to be_a Workflow::ProcessResponse
        expect(process.status).to eq 'completed'
        expect(process.name).to eq 'jp2-create'
      end
    end

    context 'when the workflow has been instantiated for the given version' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly', version: 1),
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create', version: 1),
          build(:workflow_step, :error, druid:, workflow: workflow_name, process: 'jp2-create', version: 2)
        ]
      end

      it 'returns a process' do
        expect(process).to be_a Workflow::ProcessResponse
        expect(process.status).to eq 'error'
        expect(process.error_message).to eq 'Something went wrong'
        expect(process.name).to eq 'jp2-create'
      end
    end
  end

  describe '#incomplete_processes' do
    subject(:processes) { workflow_response.incomplete_processes }

    context 'when all steps are complete' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create')
        ]
      end

      it { is_expected.to be_empty }
    end

    context 'when some steps are not complete' do
      let(:steps) do
        [
          build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly'),
          build(:workflow_step, druid:, workflow: workflow_name, process: 'jp2-create')
        ]
      end

      it 'returns the incomplete processes' do
        expect(processes.size).to eq 1
        expect(processes.first.name).to eq 'jp2-create'
      end
    end
  end

  describe '#incomplete_processes_for' do
    let(:steps) do
      [
        build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly', version: 1),
        build(:workflow_step, druid:, workflow: workflow_name, process: 'jp2-create', version: 1),
        build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'start-assembly', version: 2),
        build(:workflow_step, :completed, druid:, workflow: workflow_name, process: 'jp2-create', version: 2)
      ]
    end

    context 'when all steps are complete' do
      it 'returns empty' do
        expect(workflow_response.incomplete_processes_for(version: 2)).to be_empty
      end
    end

    context 'when some steps are not complete' do
      it 'returns false' do
        expect(workflow_response.incomplete_processes_for(version: 1).size).to eq 1
      end
    end
  end
end

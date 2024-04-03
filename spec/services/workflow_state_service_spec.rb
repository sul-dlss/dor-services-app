# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowStateService do
  subject(:service) { described_class.new(druid:, version:) }

  let(:druid) { 'druid:xz456jk0987' }

  let(:version) { 1 }

  let(:workflow_client) do
    instance_double(Dor::Workflow::Client)
  end

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '.accessioned?' do
    context 'when the object is accessioned' do
      before do
        allow(workflow_client).to receive(:lifecycle).and_return(Time.current)
      end

      it 'returns true' do
        expect(service.accessioned?).to be true
        expect(workflow_client).to have_received(:lifecycle).with(druid:, milestone_name: 'accessioned')
      end
    end

    context 'when the object is not accessioned' do
      before do
        allow(workflow_client).to receive(:lifecycle).and_return(nil)
      end

      it 'returns false' do
        expect(service.accessioned?).to be false
      end
    end
  end

  describe '.open?' do
    context 'when version 1 and not accessioning or accessioned' do
      before do
        allow(workflow_client).to receive_messages(active_lifecycle: nil, lifecycle: nil)
      end

      it 'returns true' do
        expect(service.open?).to be true
        expect(workflow_client).to have_received(:active_lifecycle).with(druid:, milestone_name: 'submitted', version: '1')
        expect(workflow_client).to have_received(:lifecycle).with(druid:, milestone_name: 'accessioned')
      end
    end

    context 'when version 1 and accessioning' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).and_return(Time.current)
      end

      it 'returns false' do
        expect(service.open?).to be false
      end
    end

    context 'when version 1 and accessioned' do
      before do
        allow(workflow_client).to receive_messages(active_lifecycle: nil, lifecycle: Time.current)
      end

      it 'returns false' do
        expect(service.open?).to be false
      end
    end

    context 'when > version 1 and there is an active versionWF' do
      let(:version) { 2 }

      before do
        allow(workflow_client).to receive(:active_lifecycle).and_return(Time.current)
      end

      it 'returns true' do
        expect(service.open?).to be true
        expect(workflow_client).to have_received(:active_lifecycle).with(druid:, milestone_name: 'opened', version: '2')
      end
    end

    context 'when > version 1 and there is not an active versionWF' do
      let(:version) { 2 }

      before do
        allow(workflow_client).to receive(:active_lifecycle).and_return(nil)
      end

      it 'returns false' do
        expect(service.open?).to be false
      end
    end
  end

  describe '.active_version_wf?' do
    context 'when there is an active versionWF' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).and_return(Time.current)
      end

      it 'returns true' do
        expect(service.active_version_wf?).to be true
        expect(workflow_client).to have_received(:active_lifecycle).with(druid:, milestone_name: 'opened', version: '1')
      end
    end

    context 'when there is not an active versionWF' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).and_return(nil)
      end

      it 'returns false' do
        expect(service.active_version_wf?).to be false
      end
    end
  end

  describe '.accessioning?' do
    context 'when there is an active accessioningWF' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).and_return(Time.current)
      end

      it 'returns true' do
        expect(service.accessioning?).to be true
        expect(workflow_client).to have_received(:active_lifecycle).with(druid:, milestone_name: 'submitted', version: '1')
      end
    end

    context 'when there is not an active accessioningWF' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).and_return(nil)
      end

      it 'returns false' do
        expect(service.accessioning?).to be false
      end
    end
  end

  describe '.active_assembly_wf?' do
    context 'when there is an active assemblyWF' do
      before do
        allow(workflow_client).to receive(:workflow_status).and_return('waiting')
      end

      it 'returns true' do
        expect(service.active_assembly_wf?).to be true
        expect(workflow_client).to have_received(:workflow_status).with(druid:, workflow: 'assemblyWF', process: 'accessioning-initiate')
      end
    end

    context 'when there is not an active assemblyWF' do
      before do
        allow(workflow_client).to receive(:workflow_status).and_return('completed')
      end

      it 'returns false' do
        expect(service.active_assembly_wf?).to be false
      end
    end
  end

  describe '.assembling?' do
    let(:response_without_workflow) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }
    let(:response_with_complete_workflow) { instance_double(Dor::Workflow::Response::Workflow, active_for?: true, complete_for?: true) }
    let(:response_with_active_workflow) { instance_double(Dor::Workflow::Response::Workflow, active_for?: true, complete_for?: false) }

    context 'when there is an active assembly workflow' do
      before do
        allow(workflow_client).to receive(:workflow).and_return(response_with_complete_workflow, response_without_workflow, response_with_active_workflow)
      end

      it 'returns true' do
        expect(service.assembling?).to be true
      end
    end

    context 'when there is not an active assembly workflow' do
      before do
        allow(workflow_client).to receive(:workflow).and_return(response_with_complete_workflow, response_without_workflow)
      end

      it 'returns false' do
        expect(service.assembling?).to be false
        expect(workflow_client).to have_received(:workflow).with(pid: druid, workflow_name: 'assemblyWF')
        expect(workflow_client).to have_received(:workflow).with(pid: druid, workflow_name: 'wasSeedPreassemblyWF')
      end
    end
  end
end

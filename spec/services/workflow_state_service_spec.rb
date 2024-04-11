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

      let(:workflow_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: true, complete_for?: false) }

      before do
        allow(workflow_client).to receive(:workflow).and_return(workflow_response)
      end

      it 'returns true' do
        expect(service.open?).to be true
        expect(workflow_client).to have_received(:workflow).with(pid: druid, workflow_name: 'versioningWF')
      end
    end

    context 'when > version 1 and there is not an active versionWF' do
      let(:version) { 2 }

      let(:workflow_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: true, complete_for?: true) }

      before do
        allow(workflow_client).to receive(:workflow).and_return(workflow_response)
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

  describe '.assembling?' do
    let(:assembly_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }
    let(:was_crawl_preassembly_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }
    let(:was_seed_preassembly_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }
    let(:gis_delivery_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }
    let(:gis_assembly_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }

    let(:process) { instance_double(Dor::Workflow::Response::Process) }

    before do
      allow(workflow_client).to receive(:workflow).with(pid: druid, workflow_name: 'assemblyWF').and_return(assembly_wf_response)
      allow(workflow_client).to receive(:workflow).with(pid: druid, workflow_name: 'wasCrawlPreassemblyWF').and_return(was_crawl_preassembly_wf_response)
      allow(workflow_client).to receive(:workflow).with(pid: druid, workflow_name: 'wasSeedPreassemblyWF').and_return(was_seed_preassembly_wf_response)
      allow(workflow_client).to receive(:workflow).with(pid: druid, workflow_name: 'gisDeliveryWF').and_return(gis_delivery_wf_response)
      allow(workflow_client).to receive(:workflow).with(pid: druid, workflow_name: 'gisAssemblyWF').and_return(gis_assembly_wf_response)
    end

    context 'when there is an active assemblyWF' do
      before do
        allow(assembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(service.assembling?).to be true
      end
    end

    context 'when there is an active wasCrawlPreassemblyWF' do
      before do
        allow(was_crawl_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(service.assembling?).to be true
      end
    end

    context 'when there is an active wasSeedPreassemblyWF' do
      before do
        allow(was_seed_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(service.assembling?).to be true
      end
    end

    context 'when there is an active gisDeliveryWF (multiple processes)' do
      before do
        allow(gis_delivery_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(service.assembling?).to be true
      end
    end

    context 'when there is an active gisDeliveryWF (single wrong process)' do
      let(:process) { instance_double(Dor::Workflow::Response::Process, name: 'not-the-step') }

      before do
        allow(gis_delivery_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process])
      end

      it 'returns true' do
        expect(service.assembling?).to be true
      end
    end

    context 'when there is an active gisAssemblyWF' do
      before do
        allow(gis_assembly_wf_response).to receive_messages(active_for?: true, complete_for?: false)
      end

      it 'returns true' do
        expect(service.assembling?).to be true
      end
    end

    context 'when only ignored steps are incomplete' do
      let(:accessioning_initiate_process) { instance_double(Dor::Workflow::Response::Process, name: 'accessioning-initiate') }
      let(:end_was_crawl_process) { instance_double(Dor::Workflow::Response::Process, name: 'end-was-crawl-preassembly') }
      let(:end_was_seed_process) { instance_double(Dor::Workflow::Response::Process, name: 'end-was-seed-preassembly') }
      let(:start_accession_process) { instance_double(Dor::Workflow::Response::Process, name: 'start-accession-workflow') }

      before do
        allow(assembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [accessioning_initiate_process])
        allow(was_crawl_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [end_was_crawl_process])
        allow(was_seed_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [end_was_seed_process])
        allow(gis_delivery_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [start_accession_process])
      end

      it 'returns false' do
        expect(service.assembling?).to be false
      end
    end

    context 'when there are no incomplete steps' do
      before do
        allow(assembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
        allow(was_crawl_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
        allow(was_seed_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
        allow(gis_delivery_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
      end

      it 'returns false' do
        expect(service.assembling?).to be false
      end
    end

    context 'when there are no assembly workflows' do
      it 'returns false' do
        expect(service.assembling?).to be false
      end
    end
  end
end

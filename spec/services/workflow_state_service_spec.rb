# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowStateService do
  subject(:workflow_state) { described_class.new(druid:, version:) }

  let(:druid) { 'druid:xz456jk0987' }
  let(:version) { 1 }
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '.accessioned?' do
    context 'when the object is accessioned' do
      before do
        allow(workflow_client).to receive(:lifecycle).and_return(Time.current)
      end

      it 'returns true' do
        expect(workflow_state).to be_accessioned
        expect(workflow_client).to have_received(:lifecycle).with(druid:, milestone_name: 'accessioned')
      end
    end

    context 'when the object is not accessioned' do
      before do
        allow(workflow_client).to receive(:lifecycle).and_return(nil)
      end

      it 'returns false' do
        expect(workflow_state).not_to be_accessioned
      end
    end
  end

  describe '.accessioning?' do
    let(:accession_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false, workflow_name: 'accessionWF') }
    let(:other_wf_response) { instance_double(Dor::Workflow::Response::Workflow, workflow_name: 'otherWF') }
    let(:wf_responses) { instance_double(Dor::Workflow::Response::Workflows, workflows: [other_wf_response, accession_wf_response]) }
    let(:process) { instance_double(Dor::Workflow::Response::Process, name: process_name) }

    before do
      allow(workflow_client).to receive(:all_workflows).with(pid: druid).and_return(wf_responses)
    end

    context 'when there is an active accessioningWF with a non-ignored step' do
      let(:process_name) { 'publish' } # or any other step in accessionWF except for end-accession

      before do
        allow(accession_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(workflow_state).to be_accessioning
        expect(workflow_client).to have_received(:all_workflows).with(pid: druid)
      end
    end

    context 'when there is an active accessioningWF with an ignored step' do
      let(:process_name) { 'end-accession' } # this step is ignored in the check for active accessioning steps

      before do
        allow(accession_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns false' do
        expect(workflow_state).not_to be_accessioning
      end
    end

    context 'when there is not an active accessioningWF' do
      before do
        allow(workflow_client).to receive(:all_workflows).with(pid: druid).and_return(wf_responses)
      end

      it 'returns false' do
        expect(workflow_state).not_to be_accessioning
      end
    end
  end

  describe '.assembling?' do
    let(:assembly_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false, workflow_name: 'assemblyWF') }
    let(:was_crawl_preassembly_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false, workflow_name: 'wasCrawlPreassemblyWF') }
    let(:was_seed_preassembly_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false, workflow_name: 'wasSeedPreassemblyWF') }
    let(:gis_delivery_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false, workflow_name: 'gisDeliveryWF') }
    let(:gis_assembly_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false, workflow_name: 'gisAssemblyWF') }
    let(:ocr_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false, workflow_name: 'ocrWF') }
    let(:stt_wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false, workflow_name: 'speechToTextWF') }
    let(:workflow_responses) do
      instance_double(Dor::Workflow::Response::Workflows, workflows: [
                        assembly_wf_response, was_crawl_preassembly_wf_response, was_seed_preassembly_wf_response,
                        gis_delivery_wf_response, gis_assembly_wf_response, ocr_wf_response, stt_wf_response
                      ])
    end
    let(:process) { instance_double(Dor::Workflow::Response::Process, name: 'arbitrary') }

    before do
      allow(workflow_client).to receive(:all_workflows).with(pid: druid).and_return(workflow_responses)
    end

    context 'when there is an active assemblyWF' do
      before do
        allow(assembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(workflow_state).to be_assembling
      end
    end

    context 'when there is an active wasCrawlPreassemblyWF' do
      before do
        allow(was_crawl_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(workflow_state).to be_assembling
      end
    end

    context 'when there is an active wasSeedPreassemblyWF' do
      before do
        allow(was_seed_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(workflow_state).to be_assembling
      end
    end

    context 'when there is an active gisDeliveryWF (multiple processes)' do
      before do
        allow(gis_delivery_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(workflow_state).to be_assembling
      end
    end

    context 'when there is an active gisDeliveryWF (single wrong process)' do
      let(:process) { instance_double(Dor::Workflow::Response::Process, name: 'not-the-step') }

      before do
        allow(gis_delivery_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process])
      end

      it 'returns true' do
        expect(workflow_state).to be_assembling
      end
    end

    context 'when there is an active gisAssemblyWF' do
      before do
        allow(gis_assembly_wf_response).to receive_messages(active_for?: true, complete_for?: false)
      end

      it 'returns true' do
        expect(workflow_state).to be_assembling
      end
    end

    context 'when there is an active ocrWF' do
      before do
        allow(ocr_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(workflow_state).to be_assembling
      end
    end

    context 'when there is an active speechToTextWF' do
      before do
        allow(stt_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [process, process])
      end

      it 'returns true' do
        expect(workflow_state).to be_assembling
      end
    end

    context 'when only ignored steps are incomplete' do
      let(:accessioning_initiate_process) { instance_double(Dor::Workflow::Response::Process, name: 'accessioning-initiate') }
      let(:end_was_crawl_process) { instance_double(Dor::Workflow::Response::Process, name: 'end-was-crawl-preassembly') }
      let(:end_was_seed_process) { instance_double(Dor::Workflow::Response::Process, name: 'end-was-seed-preassembly') }
      let(:start_accession_process) { instance_double(Dor::Workflow::Response::Process, name: 'start-accession-workflow') }
      let(:end_ocr_process) { instance_double(Dor::Workflow::Response::Process, name: 'end-ocr') }
      let(:end_stt_process) { instance_double(Dor::Workflow::Response::Process, name: 'end-stt') }

      before do
        allow(assembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [accessioning_initiate_process])
        allow(was_crawl_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [end_was_crawl_process])
        allow(was_seed_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [end_was_seed_process])
        allow(gis_delivery_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [start_accession_process])
        allow(ocr_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [end_ocr_process])
        allow(stt_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [end_stt_process])
      end

      it 'returns false' do
        expect(workflow_state).not_to be_assembling
      end
    end

    context 'when there are no incomplete steps' do
      before do
        allow(assembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
        allow(was_crawl_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
        allow(was_seed_preassembly_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
        allow(gis_delivery_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
        allow(ocr_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
        allow(stt_wf_response).to receive_messages(active_for?: true, incomplete_processes_for: [])
      end

      it 'returns false' do
        expect(workflow_state).not_to be_assembling
      end
    end

    context 'when there are no assembly workflows' do
      it 'returns false' do
        expect(workflow_state).not_to be_assembling
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Start Accession or Re-accession an object (with versioning)' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 1) }
  let(:updated_cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 2) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }
  let(:default_start_accession_workflow) { 'assemblyWF' }

  let(:params) do
    {
      description: 're-accessioning',
      opening_user_name: 'some_person'
    }
  end

  let(:version_service) { instance_double(VersionService, open: updated_cocina_object) }

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(EventFactory).to receive(:create)
  end

  context 'when already open' do
    before do
      allow(version_service).to receive(:open?).and_return(true)
    end

    it 'does not open and starts default workflow' do
      post("/v1/objects/#{druid}/accession?#{params.to_query}",
           headers: { 'Authorization' => "Bearer #{jwt}" })
      expect(response).to be_successful
      expect(EventFactory).to have_received(:create).with(
        { data: { workflow: 'assemblyWF' },
          druid: 'druid:mx123qw2323',
          event_type: 'accession_request' }
      )
      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(druid, default_start_accession_workflow, version: '1', context: nil)
      expect(version_service).not_to have_received(:open)
    end

    it 'can override the default workflow' do
      post "/v1/objects/#{druid}/accession?#{params.merge(workflow: 'gisAssemblyWF').to_query}",
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(druid, 'gisAssemblyWF', version: '1', context: nil)
    end
  end

  context 'when existing object that is not currently open' do
    before do
      allow(version_service).to receive_messages(open?: false, can_open?: true)
    end

    it 'opens a version and starts default workflow' do
      post("/v1/objects/#{druid}/accession?#{params.to_query}",
           headers: { 'Authorization' => "Bearer #{jwt}" })
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, default_start_accession_workflow,
                                                                              version: '2', context: nil)
      expect(version_service).to have_received(:open).with(
        assume_accessioned: false,
        cocina_object:,
        **params
      )
    end

    it 'can override the default workflow' do
      post "/v1/objects/#{druid}/accession?#{params.merge(workflow: 'gisAssemblyWF').to_query}",
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(druid, 'gisAssemblyWF', version: '2', context: nil)
    end

    context 'with context' do
      let(:workflow_context) { { 'requireOCR' => true } }

      it 'sends workflow context' do
        post "/v1/objects/#{druid}/accession?#{params.to_query}",
             params: { context: workflow_context }.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
        expect(workflow_client).to have_received(:create_workflow_by_name)
          .with(druid, default_start_accession_workflow, version: '2', context: workflow_context)
      end
    end
  end

  context 'when object currently closed and cannot be opened' do
    before do
      allow(version_service).to receive_messages(open?: false, can_open?: false)
    end

    it 'returns an unacceptable response and does not start any workflows' do
      post("/v1/objects/#{druid}/accession?#{params.to_query}",
           headers: { 'Authorization' => "Bearer #{jwt}" })

      expect(response).to have_http_status(:conflict)

      expect(EventFactory).to have_received(:create).with(
        { data: { workflow: 'assemblyWF' },
          druid: 'druid:mx123qw2323',
          event_type: 'accession_request' }
      )

      expect(EventFactory).to have_received(:create).with(
        { data: { workflow: 'assemblyWF' },
          druid: 'druid:mx123qw2323',
          event_type: 'accession_request_aborted' }
      )
      expect(workflow_client).not_to have_received(:create_workflow_by_name)
      expect(version_service).not_to have_received(:open)
    end
  end
end

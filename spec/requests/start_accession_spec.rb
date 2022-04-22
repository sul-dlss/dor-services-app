# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Start Accession or Re-accession an object (with versioning)' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 1) }
  let(:updated_cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 2) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }
  let(:default_start_accession_workflow) { ObjectsController.new.send(:default_start_accession_workflow) }
  let(:event_factory_param) { { event_factory: EventFactory } }
  let(:version_params) do
    {
      description: 'version for accession',
      significance: 'admin'
    }
  end

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    allow(VersionService).to receive(:close)
    allow(VersionService).to receive(:open).and_return(updated_cocina_object)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(EventFactory).to receive(:create)
  end

  context 'when newly registered object that has not been accessioned yet' do
    before do
      allow(VersionService).to receive(:in_accessioning?).and_return(false)
      allow(VersionService).to receive(:can_open?).and_return(false)
      allow(VersionService).to receive(:open?).and_return(false)
    end

    it 'does not open or close a version and starts default workflow' do
      post "/v1/objects/#{druid}/accession",
           params: version_params,
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(EventFactory).to have_received(:create).with(
        { data: { workflow: 'assemblyWF' },
          druid: 'druid:mx123qw2323',
          event_type: 'accession_request' }
      )
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, default_start_accession_workflow, version: '1')
      expect(VersionService).not_to have_received(:open)
      expect(VersionService).not_to have_received(:close)
    end

    it 'can override the default workflow' do
      post "/v1/objects/#{druid}/accession",
           params: version_params.merge({ workflow: 'accessionWF', opening_user_name: 'some_person' }),
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'accessionWF', version: '1')
      expect(VersionService).not_to have_received(:open)
      expect(VersionService).not_to have_received(:close)
    end
  end

  context 'when existing accessioned object that is not currently open' do
    before do
      allow(VersionService).to receive(:in_accessioning?).and_return(false)
      allow(VersionService).to receive(:can_open?).and_return(true)
    end

    it 'opens and closes a version and starts default workflow' do
      post "/v1/objects/#{druid}/accession",
           params: version_params,
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, default_start_accession_workflow, version: '2')
      expect(VersionService).to have_received(:can_open?).with(cocina_object, assume_accessioned: version_params[:assume_accessioned])
      expect(VersionService).to have_received(:open)
        .with(cocina_object,
              description: 'version for accession',
              significance: 'admin',
              assume_accessioned: nil,
              opening_user_name: nil,
              event_factory: EventFactory)
      expect(VersionService).to have_received(:close)
        .with(updated_cocina_object,
              description: 'version for accession',
              significance: 'admin',
              start_accession: false,
              event_factory: EventFactory)
    end

    it 'can override the default workflow' do
      # params = { 'workflow' => 'accessionWF', 'opening_user_name' => 'some_person' }
      post "/v1/objects/#{druid}/accession",
           params: version_params.merge({ 'workflow' => 'accessionWF' }),
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'accessionWF', version: '2')
      expect(VersionService).to have_received(:open)
      expect(VersionService).to have_received(:close)
    end
  end

  context 'when existing accessioned object that is currently open' do
    before do
      allow(VersionService).to receive(:in_accessioning?).and_return(false)
      allow(VersionService).to receive(:can_open?).and_return(false)
      allow(VersionService).to receive(:open?).and_return(true)
    end

    it 'closes a version and starts default workflow' do
      post "/v1/objects/#{druid}/accession",
           params: version_params,
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, default_start_accession_workflow, version: '1')
      expect(VersionService).not_to have_received(:open)
      expect(VersionService).to have_received(:close)
        .with(cocina_object,
              description: 'version for accession',
              significance: 'admin',
              start_accession: false,
              event_factory: EventFactory)
    end
  end

  context 'when object currently in accessioning' do
    before do
      allow(VersionService).to receive(:in_accessioning?).and_return(true)
    end

    it 'returns an unacceptable response and does not start any workflows' do
      post "/v1/objects/#{druid}/accession",
           params: version_params,
           headers: { 'Authorization' => "Bearer #{jwt}" }
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
      expect(VersionService).not_to have_received(:open)
      expect(VersionService).not_to have_received(:close)
      expect(response).to have_http_status(:conflict)
    end
  end
end

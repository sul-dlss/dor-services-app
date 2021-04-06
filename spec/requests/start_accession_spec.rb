# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Start Accession or Re-accession an object (with versioning)' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }
  let(:default_start_accession_workflow) { ObjectsController.new.send(:default_start_accession_workflow) }
  let(:event_factory) { { event_factory: EventFactory } }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(VersionService).to receive(:close)
    allow(VersionService).to receive(:open)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  context 'when newly registered object that has not been accessioned yet' do
    before do
      allow(VersionService).to receive(:in_accessioning?).and_return(false)
      allow(VersionService).to receive(:can_open?).and_return(false)
      allow(VersionService).to receive(:open_for_versioning?).and_return(false)
    end

    it 'does not open or close a version and starts default workflow' do
      post "/v1/objects/#{druid}/accession",
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(workflow_client).to have_received(:create_workflow_by_name).with(object.pid, default_start_accession_workflow, version: '1')
      expect(VersionService).not_to have_received(:open)
      expect(VersionService).not_to have_received(:close)
    end

    it 'can override the default workflow' do
      params = { workflow: 'accessionWF', opening_user_name: 'some_person' }
      post "/v1/objects/#{druid}/accession",
           params: params,
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(workflow_client).to have_received(:create_workflow_by_name).with(object.pid, 'accessionWF', version: '1')
      expect(VersionService).not_to have_received(:open)
      expect(VersionService).not_to have_received(:close)
    end
  end

  context 'when existing accessioned object that is not currently open' do
    let(:base_params) { { 'controller' => 'objects', 'action' => 'accession', 'id' => druid } }

    before do
      allow(VersionService).to receive(:in_accessioning?).and_return(false)
      allow(VersionService).to receive(:can_open?).and_return(true)
    end

    it 'opens and closes a version and starts default workflow' do
      post "/v1/objects/#{druid}/accession",
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).to have_received(:create_workflow_by_name).with(object.pid, default_start_accession_workflow, version: '1')
      expect(VersionService).to have_received(:open).with(object, base_params, event_factory)
      expect(VersionService).to have_received(:close).with(object, base_params.merge('start_accession' => false), event_factory)
    end

    it 'can override the default workflow' do
      params = { 'workflow' => 'accessionWF', 'opening_user_name' => 'some_person' }
      post "/v1/objects/#{druid}/accession",
           params: params,
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).to have_received(:create_workflow_by_name).with(object.pid, 'accessionWF', version: '1')
      expect(VersionService).to have_received(:open).with(object, base_params.merge(params), event_factory)
      expect(VersionService).to have_received(:close).with(object, base_params.merge(params).merge('start_accession' => false), event_factory)
    end
  end

  context 'when existing accessioned object that is currently open' do
    let(:base_params) { { 'controller' => 'objects', 'action' => 'accession', 'id' => druid } }

    before do
      allow(VersionService).to receive(:in_accessioning?).and_return(false)
      allow(VersionService).to receive(:can_open?).and_return(false)
      allow(VersionService).to receive(:open_for_versioning?).and_return(true)
    end

    it 'closes a version and starts default workflow' do
      post "/v1/objects/#{druid}/accession",
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).to have_received(:create_workflow_by_name).with(object.pid, default_start_accession_workflow, version: '1')
      expect(VersionService).not_to have_received(:open).with(object, base_params, event_factory)
      expect(VersionService).to have_received(:close).with(object, base_params.merge('start_accession' => false), event_factory)
    end
  end

  context 'when object currently in accessioning' do
    let(:base_params) { { 'controller' => 'objects', 'action' => 'accession', 'id' => druid } }

    before do
      allow(VersionService).to receive(:in_accessioning?).and_return(true)
    end

    it 'returns an unacceptable response and does not start any workflows' do
      post "/v1/objects/#{druid}/accession",
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).not_to have_received(:create_workflow_by_name)
      expect(VersionService).not_to have_received(:open)
      expect(VersionService).not_to have_received(:close)
      expect(response).to have_http_status(:not_acceptable)
    end
  end
end

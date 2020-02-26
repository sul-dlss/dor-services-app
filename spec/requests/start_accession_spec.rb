# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Start Accession or Re-accession an object (with versioning)' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }
  let(:default_start_accession_workflow) { ObjectsController.new.send(:default_start_accession_workflow) }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(VersionService).to receive(:close)
    allow(VersionService).to receive(:open)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  context 'when new object' do
    before do
      allow(VersionService).to receive(:can_open?).and_return(false)
    end

    it 'does not open or close a version and starts default workflow' do
      post "/v1/objects/#{druid}/start_accession",
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(workflow_client).to have_received(:create_workflow_by_name).with(object.pid, default_start_accession_workflow, version: '1')
      expect(VersionService).not_to have_received(:open)
      expect(VersionService).not_to have_received(:close)
    end

    it 'can override the default workflow' do
      params = { workflow: 'accessionWF', opening_user_name: 'some_person' }
      post "/v1/objects/#{druid}/start_accession",
           params: params,
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(workflow_client).to have_received(:create_workflow_by_name).with(object.pid, 'accessionWF', version: '1')
      expect(VersionService).not_to have_received(:open)
      expect(VersionService).not_to have_received(:close)
    end
  end

  context 'when existing object' do
    let(:base_params) { { 'controller' => 'objects', 'action' => 'start_accession', 'id' => druid } }

    before do
      allow(VersionService).to receive(:can_open?).and_return(true)
    end

    it 'opens and closes a version and starts default workflow' do
      post "/v1/objects/#{druid}/start_accession",
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).to have_received(:create_workflow_by_name).with(object.pid, default_start_accession_workflow, version: '1')
      expect(VersionService).to have_received(:open).with(base_params.merge('workflow' => default_start_accession_workflow))
      expect(VersionService).to have_received(:close).with(base_params.merge('workflow' => default_start_accession_workflow, 'start_accession' => false))
    end

    it 'can override the default workflow' do
      params = { 'workflow' => 'accessionWF', 'opening_user_name' => 'some_person' }
      post "/v1/objects/#{druid}/start_accession",
           params: params,
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(workflow_client).to have_received(:create_workflow_by_name).with(object.pid, 'accessionWF', version: '1')
      expect(VersionService).to have_received(:open).with(base_params.merge(params))
      expect(VersionService).to have_received(:close).with(base_params.merge(params).merge('start_accession' => false))
    end
  end
end

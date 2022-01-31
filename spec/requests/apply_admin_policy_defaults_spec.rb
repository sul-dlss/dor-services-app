# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO access defaults to a member item' do
  before do
    allow(CocinaObjectStore).to receive(:find).with(object_druid).and_return(cocina_object)
    allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(cocina_admin_policy)
    allow(CocinaObjectStore).to receive(:save)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  let(:apo_druid) { 'druid:df123cd4567' }
  let(:object_druid) { 'druid:bc123df4567' }
  let(:cocina_admin_policy) do
    Cocina::Models::AdminPolicy.new(
      externalIdentifier: apo_druid,
      version: 1,
      type: Cocina::Models::Vocab.admin_policy,
      label: 'Dummy APO',
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431',
        hasAgreement: 'druid:bc753qt7345',
        defaultAccess: default_access
      }
    )
  end
  let(:cocina_object) do
    Cocina::Models::DRO.new(
      externalIdentifier: object_druid,
      version: 1,
      type: Cocina::Models::Vocab.object,
      label: 'Dummy Object',
      access: {},
      administrative: { hasAdminPolicy: apo_druid }
    )
  end
  let(:default_access) do
    {
      access: 'world',
      download: 'world'
    }
  end
  let(:workflow_client) { instance_double(Dor::Workflow::Client, status: status_client) }
  let(:status_client) { instance_double(Dor::Workflow::Client::Status, display_simplified: workflow_state) }

  AdminPolicyDefaultsController::ALLOWED_WORKFLOW_STATES.each do |workflow_state|
    context "when item is in '#{workflow_state}' state" do
      let(:workflow_state) { workflow_state }

      context 'when APO picks up default default object rights' do
        it 'copies APO defaultAccess to item access' do
          post "/v1/objects/#{object_druid}/apply_admin_policy_defaults",
               headers: { 'Authorization' => "Bearer #{jwt}" }
          expect(response).to be_successful
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with_access(default_access))
        end
      end

      context 'when APO specifies custom default object rights' do
        let(:default_access) do
          {
            access: 'world',
            download: 'none',
            useAndReproductionStatement: 'Use at will.',
            license: 'https://creativecommons.org/licenses/by-nc/3.0/legalcode'
          }
        end

        it 'copies APO defaultAccess to item access' do
          post "/v1/objects/#{object_druid}/apply_admin_policy_defaults",
               headers: { 'Authorization' => "Bearer #{jwt}" }
          expect(response).to be_successful
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with_access(default_access))
        end
      end
    end
  end

  ['Unknown Status', 'In accessioning', 'Accessioned'].each do |workflow_state|
    context "when item is in '#{workflow_state}' state" do
      let(:workflow_state) { workflow_state }

      it 'returns an HTTP 422 response with an error message' do
        post "/v1/objects/#{object_druid}/apply_admin_policy_defaults",
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(JSON.parse(response.body)['errors'].first['detail']).to include(
          "is in a state in which it cannot be modified (#{workflow_state}): APO defaults " \
          'can only be applied when an object is either registered or opened for versioning'
        )
        expect(response).not_to be_successful
        expect(response).to have_http_status(:unprocessable_entity)
        expect(CocinaObjectStore).not_to have_received(:save)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(object).to receive(:save!)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  let(:object) { Dor::Item.new(admin_policy_object: admin_policy) }
  let(:admin_policy) do
    Dor::AdminPolicyObject.new.tap do |coll|
      coll.defaultObjectRights.content = '<foo/>'
    end
  end
  let(:workflow_client) { instance_double(Dor::Workflow::Client, status: status_client) }
  let(:status_client) { instance_double(Dor::Workflow::Client::Status, display_simplified: workflow_state) }

  AdminPolicyDefaultsController::ALLOWED_WORKFLOW_STATES.each do |workflow_state|
    context "when item is in '#{workflow_state}' state" do
      let(:workflow_state) { workflow_state }

      it 'copies the rights metadata from the AdminPolicy to the object' do
        post '/v1/objects/druid:mk420bs7601/apply_admin_policy_defaults',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to be_successful
        expect(object.rightsMetadata.content).to eq '<foo/>'
        expect(object).to have_received(:save!)
      end
    end
  end

  ['Unknown Status', 'In accessioning', 'Accessioned'].each do |workflow_state|
    context "when item is in '#{workflow_state}' state" do
      let(:workflow_state) { workflow_state }

      it 'returns an HTTP 422 response with an error message' do
        post '/v1/objects/druid:mk420bs7601/apply_admin_policy_defaults',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(JSON.parse(response.body)['errors'].first['detail']).to include(
          "is in a state in which it cannot be modified (#{workflow_state}): APO defaults " \
          'can only be applied when an object is either registered or opened for versioning'
        )
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).not_to be_successful
        expect(object).not_to have_received(:save!)
      end
    end
  end
end

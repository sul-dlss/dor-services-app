# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a workflow' do
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }

  let(:druid) { 'druid:mx123qw2323' }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  it 'creates a workflow' do
    post '/v1/objects/druid:mx123qw2323/workflows/etdSubmitWF?version=1',
         headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to have_http_status(:created)
    expect(workflow_client).to have_received(:create_workflow_by_name)
      .with(druid, 'etdSubmitWF', version: 1, lane_id: 'default', context: nil)
  end

  context 'with a lane id and context' do
    let(:context) { { 'foo' => 'bar' } }

    it 'creates a workflow with lane id and context' do
      post '/v1/objects/druid:mx123qw2323/workflows/etdSubmitWF?version=1&lane-id=low',
           headers: { 'Authorization' => "Bearer #{jwt}" },
           params: { context: context },
           as: :json
      expect(response).to have_http_status(:created)
      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(druid, 'etdSubmitWF', version: 1, lane_id: 'low', context:)
    end
  end
end

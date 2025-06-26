# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get a workflow process status' do
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_status:) }

  let(:druid) { 'druid:mx123qw2323' }
  let(:workflow_status) { 'completed' }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  it 'returns the status' do
    get "/v1/objects/#{druid}/workflows/accessionWF/processes/shelve",
        headers: { 'Authorization' => "Bearer #{jwt}" },
        as: :json
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq({ status: workflow_status }.to_json)
    expect(workflow_client).to have_received(:workflow_status)
      .with(druid:, workflow: 'accessionWF', process: 'shelve')
  end
end

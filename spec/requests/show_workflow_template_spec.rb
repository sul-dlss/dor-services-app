# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get workflow template' do
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_template: template) }
  let(:template) do
    '{"processes":[{"name":"start-assembly"},{"name":"content-metadata-create"}]}'
  end

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  it 'returns the named template' do
    get '/v1/workflow_templates/whateverWF', headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(response.parsed_body).to match(JSON.parse(template))
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'List workflow templates' do
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_templates: templates) }

  let(:templates) { ['assemblyWF', 'registrationWF'] }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  it 'returns the templates' do
    get '/v1/workflow_templates',
        headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(response.parsed_body).to match(templates)
  end
end

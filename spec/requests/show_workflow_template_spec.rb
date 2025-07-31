# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get workflow template' do
  let(:template) do
    '{"processes":[{"name":"start-assembly"},{"name":"content-metadata-create"}]}'
  end

  before do
    allow(Workflow::TemplateService).to receive(:template).with(workflow_name: 'whateverWF').and_return(template)
  end

  it 'returns the named template' do
    get '/v1/workflow_templates/whateverWF', headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(response.parsed_body).to match(JSON.parse(template))
  end
end

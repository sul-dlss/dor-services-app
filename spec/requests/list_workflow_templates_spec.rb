# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'List workflow templates' do
  let(:templates) { ['assemblyWF', 'registrationWF'] }

  before do
    allow(Workflow::TemplateService).to receive(:templates).and_return(templates)
  end

  it 'returns the templates' do
    get '/v1/workflow_templates',
        headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to be_successful
    expect(response.parsed_body).to match(templates)
  end
end

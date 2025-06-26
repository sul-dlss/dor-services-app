# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Skipping all workflow steps' do
  let(:workflow_client) { instance_double(Dor::Workflow::Client, skip_all: true) }

  let(:druid) { 'druid:mx123qw2323' }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  it 'skips a workflow' do
    post '/v1/objects/druid:mx123qw2323/workflows/etdSubmitWF/skip_all?note=Skipping all steps',
         headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to have_http_status(:no_content)
    expect(workflow_client).to have_received(:skip_all)
      .with(druid:, workflow: 'etdSubmitWF', note: 'Skipping all steps')
  end
end

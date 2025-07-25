# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a workflow' do
  let(:druid) { 'druid:mx123qw2323' }

  before do
    allow(WorkflowService).to receive(:create)
  end

  it 'creates a workflow' do
    post '/v1/objects/druid:mx123qw2323/workflows/etdSubmitWF?version=1',
         headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to have_http_status(:created)
    expect(WorkflowService).to have_received(:create)
      .with(druid:, workflow_name: 'etdSubmitWF', version: 1, lane_id: 'default', context: nil)
  end

  context 'with a lane id and context' do
    let(:context) { { 'foo' => 'bar' } }

    it 'creates a workflow with lane id and context' do
      post '/v1/objects/druid:mx123qw2323/workflows/etdSubmitWF?version=1&lane-id=low',
           headers: { 'Authorization' => "Bearer #{jwt}" },
           params: { context: context },
           as: :json
      expect(response).to have_http_status(:created)
      expect(WorkflowService).to have_received(:create)
        .with(druid:, workflow_name: 'etdSubmitWF', version: 1, lane_id: 'low', context:)
    end
  end
end

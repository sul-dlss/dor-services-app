# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Skipping all workflow steps' do
  let(:druid) { 'druid:mx123qw2323' }

  before do
    allow(Workflow::Service).to receive(:skip_all)
  end

  it 'skips a workflow' do
    post '/v1/objects/druid:mx123qw2323/workflows/etdSubmitWF/skip_all?note=Skipping all steps',
         headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to have_http_status(:no_content)
    expect(Workflow::Service).to have_received(:skip_all)
      .with(druid:, workflow_name: 'etdSubmitWF', note: 'Skipping all steps')
  end
end

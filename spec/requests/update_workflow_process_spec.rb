# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update a workflow process' do
  let(:druid) { 'druid:mx123qw2323' }

  before do
    allow(Workflow::ProcessService).to receive(:update)
    allow(Workflow::ProcessService).to receive(:update_error)
  end

  context 'when updating status' do
    it 'updates the status' do
      put '/v1/objects/druid:mx123qw2323/workflows/accessionWF/processes/shelve',
          headers: { 'Authorization' => "Bearer #{jwt}" },
          params: { status: 'completed' },
          as: :json
      expect(response).to have_http_status(:no_content)
      expect(Workflow::ProcessService).to have_received(:update)
        .with(druid:, workflow_name: 'accessionWF', process: 'shelve', status: 'completed', elapsed:  0,
              lifecycle: nil, note: nil, current_status: nil)
    end
  end

  context 'when updating status with params' do
    it 'updates the status' do
      put '/v1/objects/druid:mx123qw2323/workflows/accessionWF/processes/shelve',
          headers: { 'Authorization' => "Bearer #{jwt}" },
          params: { status: 'completed', elapsed: 5.1, lifecycle: 'accession', note: 'Test note',
                    current_status: 'started' },
          as: :json
      expect(response).to have_http_status(:no_content)
      expect(Workflow::ProcessService).to have_received(:update)
        .with(druid:, workflow_name: 'accessionWF', process: 'shelve', status: 'completed', elapsed:  5.1,
              lifecycle: 'accession', note: 'Test note', current_status: 'started')
    end
  end

  context 'when updating status with an error' do
    it 'updates the status' do
      put '/v1/objects/druid:mx123qw2323/workflows/accessionWF/processes/shelve',
          headers: { 'Authorization' => "Bearer #{jwt}" },
          params: { status: 'error', error_msg: 'Something went wrong', error_text: 'Detailed error message' },
          as: :json
      expect(response).to have_http_status(:no_content)
      expect(Workflow::ProcessService).to have_received(:update_error)
        .with(druid:, workflow_name: 'accessionWF', process: 'shelve', error_msg: 'Something went wrong',
              error_text: 'Detailed error message')
    end
  end

  context 'when current status mismatch' do
    before do
      allow(Workflow::ProcessService).to receive(:update).and_raise(Workflow::Service::ConflictException)
    end

    it 'returns a conflict' do
      put '/v1/objects/druid:mx123qw2323/workflows/accessionWF/processes/shelve',
          headers: { 'Authorization' => "Bearer #{jwt}" },
          params: { status: 'completed', elapsed: 5.1, lifecycle: 'accession', note: 'Test note',
                    current_status: 'started' },
          as: :json
      expect(response).to have_http_status(:conflict)
    end
  end
end

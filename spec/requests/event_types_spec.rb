# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'List event types' do
  it 'returns the event types' do
    get '/v1/event_types', headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq Event::EVENT_TYPES.sort
    expect(response.parsed_body).to include('version_close', 'legacy_metadata_update')
  end

  context 'without a token' do
    it 'returns unauthorized' do
      get '/v1/event_types'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

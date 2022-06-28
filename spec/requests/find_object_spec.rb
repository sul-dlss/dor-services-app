# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  context 'when the requested object is an item' do
    let(:object) { create(:ar_dro) }

    it 'returns the object' do
      get "/v1/objects/find?sourceId=#{object.identification['sourceId']}",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
      expect(response.headers['Last-Modified']).to end_with 'GMT'
      expect(response.headers['X-Created-At']).to end_with 'GMT'
      expect(response.headers['ETag']).to match(%r{W/".+"})
      expect(response.body).to include(object.external_identifier)
    end
  end

  context 'when the requested object is a collection' do
    let(:object) { create(:ar_collection) }

    it 'returns the object' do
      get "/v1/objects/find?sourceId=#{object.identification['sourceId']}",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(object.external_identifier)
    end
  end

  context 'when the requested object is not found' do
    let(:object) { create(:ar_collection) }

    it 'returns not found' do
      get '/v1/objects/find?sourceId=sul:abc123',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:not_found)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add and retrieve events' do
  let(:druid) { 'druid:bc123df4567' }

  context 'when update is successful' do
    let(:data) do
      <<~JSON
        {
          "event_type": "publish",
          "data": {
            "size": 1900,
            "description": "stuff"
          }
        }
      JSON
    end

    it 'creates events' do
      post "/v1/objects/#{druid}/events",
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(response).to have_http_status(:created)

      get "/v1/objects/#{druid}/events",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json[0]['event_type']).to eq 'publish'
      expect(json[0]['data']).to eq('description' => 'stuff', 'size' => 1900)
      expect(json[0]).to have_key 'created_at'
    end
  end
end

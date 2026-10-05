# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add and retrieve events' do
  let(:druid) { 'druid:bc123df4567' }

  context 'when update is successful' do
    let(:data) do
      <<~JSON
        {
          "event_type": "publishing_complete",
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
      json = response.parsed_body
      expect(json[0]['event_type']).to eq 'publishing_complete'
      expect(json[0]['data']).to eq('description' => 'stuff', 'size' => 1900)
      expect(json[0]).to have_key 'created_at'
    end

    context 'when there are multiple events' do
      before do
        create(:event, druid:, event_type: 'publishing_complete')
        create(:event, druid:, event_type: 'shelving_complete')
      end

      it 'returns events in chronological order, newest first' do
        get "/v1/objects/#{druid}/events",
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json[0]['event_type']).to eq 'shelving_complete'
        expect(json[1]['event_type']).to eq 'publishing_complete'
      end
    end

    context 'when events are limited by type' do
      before do
        create(:event, druid:, event_type: 'publishing_complete')
        create(:event, druid:, event_type: 'shelving_complete')
      end

      it 'returns event of that type' do
        get "/v1/objects/#{druid}/events?event_types[]=shelving_complete&event_types[]=foo",
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.length).to eq 1
        expect(json[0]['event_type']).to eq 'shelving_complete'
      end
    end
  end

  context 'when the event type is unknown' do
    let(:data) do
      <<~JSON
        {
          "event_type": "important_action_completed",
          "data": {}
        }
      JSON
    end

    it 'returns a bad request and does not create an event' do
      expect do
        post "/v1/objects/#{druid}/events",
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      end.not_to change(Event, :count)
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['errors'][0]['detail'])
        .to eq 'Validation failed: Event type is not included in the list'
    end
  end
end

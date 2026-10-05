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

    context 'when events are limited by created_at' do
      subject(:event_types) do
        get "/v1/objects/#{druid}/events", params: query, headers: { 'Authorization' => "Bearer #{jwt}" }
        response.parsed_body.pluck('event_type')
      end

      before do
        create(:event, druid:, event_type: 'version_open', created_at: Time.utc(2026, 9, 30, 12))
        create(:event, druid:, event_type: 'update', created_at: Time.utc(2026, 10, 1, 12))
        create(:event, druid:, event_type: 'version_close', created_at: Time.utc(2026, 10, 2))
      end

      context 'with from' do
        let(:query) { { from: '2026-10-01' } }

        it { is_expected.to eq %w[version_close update] }
      end

      context 'with to' do
        let(:query) { { to: '2026-10-02' } }

        it 'excludes events created at to' do
          expect(event_types).to eq %w[update version_open]
        end
      end

      context 'with from and to' do
        let(:query) { { from: '2026-10-01', to: '2026-10-02' } }

        it { is_expected.to eq %w[update] }
      end

      context 'with a date-time with an offset' do
        # 2026-10-01T06:00:00-07:00 is 2026-10-01T13:00:00Z
        let(:query) { { from: '2026-10-01T06:00:00-07:00' } }

        it { is_expected.to eq %w[version_close] }
      end

      context 'with event types' do
        let(:query) { { from: '2026-10-01', event_types: ['update'] } }

        it { is_expected.to eq %w[update] }
      end

      context 'with an invalid from' do
        it 'returns a bad request' do
          get "/v1/objects/#{druid}/events", params: { from: 'yesterday' },
                                             headers: { 'Authorization' => "Bearer #{jwt}" }
          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body['errors'][0]['detail']).to eq 'from must be an ISO 8601 date or date-time'
        end
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

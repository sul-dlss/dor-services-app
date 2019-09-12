# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update embargo' do
  let(:payload) { { sub: 'argo' } }
  let(:jwt) { JWT.encode(payload, Settings.dor.hmac_secret, 'HS256') }
  let(:item) { Dor::Item.new(pid: 'druid:1234') }
  let(:mock_embargo_service) { instance_double(Dor::EmbargoService) }
  let(:events_datastream) { instance_double(Dor::EventsDS, add_event: true) }

  before do
    allow(Dor).to receive(:find).and_return(item)
    allow(item).to receive(:events).and_return(events_datastream)
  end

  context 'without the :embargo_date param' do
    it 'returns HTTP 400' do
      patch '/v1/objects/druid:mk420bs7601/embargo',
            headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(400)
      expect(response.body).to eq('{"errors":[{"title":"bad request","detail":"param is missing or the value is empty: embargo_date"}]}')
    end
  end

  context 'without the :requesting_user param' do
    it 'returns HTTP 400' do
      patch '/v1/objects/druid:mk420bs7601/embargo',
            params: { embargo_date: '2100-01-01' },
            headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(events_datastream).not_to have_received(:add_event)
      expect(response.status).to eq(400)
      expect(response.body).to eq('{"errors":[{"title":"bad request","detail":"param is missing or the value is empty: requesting_user"}]}')
    end
  end

  context 'when Dor::EmbargoService raises an ArgumentError' do
    let(:error_message) { 'You cannot change the embargo date of an item that is not embargoed.' }

    before do
      allow(Dor::EmbargoService).to receive(:new).and_return(mock_embargo_service)
      allow(mock_embargo_service).to receive(:update).and_raise(ArgumentError, error_message)
    end

    it 'hits the Dor::EmbargoService and returns HTTP 422' do
      patch '/v1/objects/druid:mk420bs7601/embargo',
            params: { embargo_date: '2100-01-01', requesting_user: 'mjg' },
            headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(mock_embargo_service).to have_received(:update).once
      expect(events_datastream).not_to have_received(:add_event)
      expect(response.status).to eq(422)
      expect(response.body).to eq(error_message)
    end
  end

  context 'when Dor::EmbargoService succeeds' do
    before do
      allow(Dor::EmbargoService).to receive(:new).and_return(mock_embargo_service)
      allow(mock_embargo_service).to receive(:update)
    end

    it 'hits the Dor::EmbargoService and returns HTTP 204' do
      patch '/v1/objects/druid:mk420bs7601/embargo',
            params: { embargo_date: '2100-01-01', requesting_user: 'mjg' },
            headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(mock_embargo_service).to have_received(:update).with(Date.parse('2100-01-01'))
      expect(events_datastream).to have_received(:add_event).with(
        'Embargo',
        'mjg',
        'Embargo date modified'
      )
      expect(response.status).to eq(204)
    end
  end
end

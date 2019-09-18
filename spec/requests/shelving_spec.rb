# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Shelve object' do
  let(:payload) { { sub: 'argo' } }
  let(:jwt) { JWT.encode(payload, Settings.dor.hmac_secret, 'HS256') }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(ShelvingService).to receive(:shelve)
  end

  context 'with a collection' do
    let(:object) { Dor::Collection.new(pid: 'druid:1234') }

    it 'returns a 422 error' do
      post '/v1/objects/druid:1234/shelve', headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(422)
      json = JSON.parse(response.body)
      expect(json['errors'].first['detail']).to eq("A Dor::Item is required but you provided 'Dor::Collection'")
      expect(ShelvingService).not_to have_received(:shelve)
    end
  end

  context 'when the request is successful' do
    let(:object) { Dor::Item.new(pid: 'druid:1234') }

    it 'calls ShelvingService and returns 201' do
      post '/v1/objects/druid:1234/shelve', headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.status).to eq(201)
      expect(ShelvingService).to have_received(:shelve)
    end
  end
end

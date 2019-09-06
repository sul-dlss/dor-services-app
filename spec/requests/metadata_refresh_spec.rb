# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh metadata' do
  let(:payload) { { sub: 'argo' } }
  let(:jwt) { JWT.encode(payload, Settings.dor.hmac_secret, 'HS256') }
  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(object).to receive(:save)
  end

  context 'when happy path' do
    before do
      allow(RefreshMetadataAction).to receive(:run).and_return('<xml />')
    end

    it 'updates the metadata and saves the changes' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(RefreshMetadataAction).to have_received(:run).with(object)
      expect(object).to have_received(:save)
    end
  end

  context 'when incomplete response from Symphony' do
    before do
      allow(object.identityMetadata).to receive(:otherId).and_return(['catkey:666'])
      stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: '666')).to_return(body: '{}', headers: { 'Content-Length': 0 })
    end

    it 'returns a 500 error' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(response.status).to eq(500)
      expect(response.body).to eq('Incomplete response received from Symphony for 666 - expected 0 bytes but got 2')
    end
  end
end

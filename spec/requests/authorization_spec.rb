# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authorization' do
  let(:user) { Settings.DOR.SERVICE_USER }
  let(:password) { Settings.DOR.SERVICE_PASSWORD }
  let(:basic_auth) { ActionController::HttpAuthentication::Basic.encode_credentials(user, password) }
  let(:object) { instance_double(Dor::Item, current_version: '5') }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(Honeybadger).to receive(:notify)
    allow(Honeybadger).to receive(:context)
  end

  context 'without a bearer token' do
    it 'Logs tokens to honeybadger' do
      get '/v1/objects/druid:mk420bs7601/versions/current',
          headers: { 'Authorization' => basic_auth }
      expect(response.body).to eq '5'
      expect(Honeybadger).to have_received(:notify).with('no X-Auth token was provided by 127.0.0.1')
    end
  end

  context 'with a bearer token' do
    let(:payload) { { sub: 'argo' } }
    let(:jwt) { JWT.encode(payload, Settings.dor.hmac_secret, 'HS256') }

    it 'Logs tokens to honeybadger' do
      get '/v1/objects/druid:mk420bs7601/versions/current',
          headers: { 'Authorization' => basic_auth, 'X-Auth' => "Bearer #{jwt}" }
      expect(response.body).to eq '5'
      expect(Honeybadger).not_to have_received(:notify)
      expect(Honeybadger).to have_received(:context).with(invoked_by: 'argo')
    end
  end
end

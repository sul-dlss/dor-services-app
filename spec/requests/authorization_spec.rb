# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authorization' do
  let(:object) { instance_double(Dor::Item, current_version: '5') }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(Honeybadger).to receive(:notify)
    allow(Honeybadger).to receive(:context)
  end

  context 'without a bearer token' do
    it 'Logs tokens to honeybadger' do
      get '/v1/objects/druid:mk420bs7601/versions/current',
          headers: {}
      expect(response.body).to eq '{"error":"Not Authorized"}'
      expect(response).to be_unauthorized
    end
  end

  context 'with a bearer token' do
    it 'Logs tokens to honeybadger' do
      get '/v1/objects/druid:mk420bs7601/versions/current',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.body).to eq '5'
      expect(Honeybadger).not_to have_received(:notify)
      expect(Honeybadger).to have_received(:context).with(invoked_by: 'argo')
    end
  end
end

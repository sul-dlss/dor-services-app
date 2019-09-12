# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  let(:payload) { { sub: 'argo' } }
  let(:jwt) { JWT.encode(payload, Settings.dor.hmac_secret, 'HS256') }
  let(:basic_auth) { ActionController::HttpAuthentication::Basic.encode_credentials(user, password) }
  let(:object) { instance_double(Dor::Item, collections: [collection]) }
  let(:collection_id) { 'druid:999123' }
  let(:collection) do
    Dor::Collection.new(pid: collection_id, label: 'collection #1')
  end

  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  describe 'as used by WAS crawl seed registration' do
    it 'returns (at a minimum) the identifiers of the collections ' do
      get '/v1/objects/druid:mk420bs7601/query/collections',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.body).to eq '{"collections":[{"externalIdentifier":"druid:999123","type":"collection","label":"collection #1"}]}'
    end
  end
end

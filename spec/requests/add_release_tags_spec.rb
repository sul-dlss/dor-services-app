# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add release tags' do
  let(:payload) { { sub: 'argo' } }
  let(:jwt) { JWT.encode(payload, Settings.dor.hmac_secret, 'HS256') }
  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(ReleaseTags).to receive(:create)
    allow(object).to receive(:save)
  end

  context 'when release is false' do
    it 'adds a release tag' do
      post '/v1/objects/druid:1234/release_tags',
           params: %( {"to":"searchworks","who":"carrickr","what":"self","release":false} ),
           headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(ReleaseTags).to have_received(:create)
        .with(Dor::Item, release: false, to: 'searchworks', who: 'carrickr', what: 'self')
      expect(object).to have_received(:save)

      expect(response.status).to eq(201)
    end
  end

  context 'when release is true' do
    it 'adds a release tag' do
      post '/v1/objects/druid:1234/release_tags',
           params: %( {"to":"searchworks","who":"carrickr","what":"self","release":true} ),
           headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(ReleaseTags).to have_received(:create)
        .with(Dor::Item, release: true, to: 'searchworks', who: 'carrickr', what: 'self')
      expect(object).to have_received(:save)
      expect(response.status).to eq(201)
    end
  end

  context 'with an invalid release attribute' do
    it 'returns an error' do
      post '/v1/objects/druid:1234/release_tags',
           params: %( {"to":"searchworks","who":"carrickr","what":"self","release":"seven"} ),
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(400)
    end
  end

  context 'with a missing release attribute' do
    it 'returns an error' do
      post '/v1/objects/druid:1234/release_tags',
           params: %( {"to":"searchworks","who":"carrickr","what":"self"} ),
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(400)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Notify Goobi' do
  let(:payload) { { sub: 'argo' } }
  let(:jwt) { JWT.encode(payload, Settings.dor.hmac_secret, 'HS256') }
  let(:object) { Dor::Item.new(pid: 'druid:1234') }
  let(:fake_request) { "<stanfordCreationRequest><objectId>#{object.pid}</objectId></stanfordCreationRequest>" }

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow_any_instance_of(Dor::Goobi).to receive(:xml_request).and_return fake_request
  end

  context 'when it is successful' do
    before do
      stub_request(:post, Settings.goobi.url)
        .to_return(body: fake_request,
                   headers: { 'Content-Type' => 'application/xml' },
                   status: 201)
    end

    it 'notifies goobi of a new registration by making a web service call' do
      post '/v1/objects/druid:1234/notify_goobi', headers: { 'X-Auth' => "Bearer #{jwt}" }

      expect(response.status).to eq(201)
    end
  end

  context 'when it is a conflict' do
    before do
      stub_request(:post, Settings.goobi.url)
        .to_return(body: 'conflict',
                   status: 409)
    end

    it 'returns the conflict code' do
      post '/v1/objects/druid:1234/notify_goobi', headers: { 'X-Auth' => "Bearer #{jwt}" }
      expect(response.status).to eq(409)
      expect(response.body).to eq('conflict')
    end
  end
end

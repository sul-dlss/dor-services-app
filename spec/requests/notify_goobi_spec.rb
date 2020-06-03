# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Notify Goobi' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }
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
      post "/v1/objects/#{druid}/notify_goobi", headers: { 'Authorization' => "Bearer #{jwt}" }

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
      post "/v1/objects/#{druid}/notify_goobi", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq 409
      expect(response.body).to eq '{"errors":[{"status":"409","title":"Conflict","detail":"conflict"}]}'
    end
  end
end

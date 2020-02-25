# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Register object' do
  let(:object) { Dor::Item.new(pid: 'druid:1234') }
  let(:data) { '{"admin_policy":"druid:mk420bs7601","source_id":"ns:ident"}' }

  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  context 'when an object already exists' do
    before do
      allow(RegistrationService).to receive(:register_object).and_raise(Dor::DuplicateIdError.new('druid:existing123obj'))
    end

    it 'returns a 409 error' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(409)
    end
  end

  context 'when an object has a bad name' do
    let(:errmsg) { 'my unique snowflake error message' }

    before do
      allow(RegistrationService).to receive(:register_object).and_raise(ArgumentError.new(errmsg))
    end

    it 'returns a 422 error' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(422)
      expect(response.body).to eq(errmsg)
    end
  end

  context 'when the SymphonyReader gets an incomplete response' do
    let(:errmsg) { 'my unique snowflake error message' }

    before do
      allow(RegistrationService).to receive(:register_object).and_raise(SymphonyReader::ResponseError.new(errmsg))
    end

    it 'returns a 502 error' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(502)
      expect(response.body).to eq(errmsg)
    end
  end

  context 'when the object is missing from fedora' do
    let(:errmsg) { 'my unique snowflake error message' }

    before do
      allow(RegistrationService).to receive(:register_object).and_raise(ActiveFedora::ObjectNotFoundError.new(errmsg))
    end

    it 'returns a 404 error' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(404)
      expect(response.body).to eq(errmsg)
    end
  end

  context 'when the request is successful' do
    before do
      allow(RegistrationService).to receive(:create_from_request).and_return(reg_response)
    end

    let(:reg_response) do
      instance_double(Dor::RegistrationResponse, to_txt: 'druid:xyz',
                                                 location: 'https://fedora.example.com:3333/fedora/objects/druid:xyz')
    end

    it 'registers the object with the registration service' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to eq 'druid:xyz'
      expect(RegistrationService).to have_received(:create_from_request)
        .with({ 'admin_policy' => 'druid:mk420bs7601', 'source_id' => 'ns:ident' },
              event_factory: EventFactory)
      expect(response.status).to eq(201)
      expect(response.location).to end_with '/fedora/objects/druid:xyz'
    end
  end
end

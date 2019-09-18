# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Register object' do
  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  context 'when an object already exists' do
    before do
      allow(RegistrationService).to receive(:register_object).and_raise(Dor::DuplicateIdError.new('druid:existing123obj'))
    end

    it 'returns a 409 error with location header' do
      post '/v1/objects', headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(409)
      expect(response.headers['Location']).to match(%r{/fedora/objects/druid:existing123obj})
    end
  end

  context 'when an object has a bad name' do
    let(:errmsg) { 'my unique snowflake error message' }

    before do
      allow(RegistrationService).to receive(:register_object).and_raise(ArgumentError.new(errmsg))
    end

    it 'returns a 422 error' do
      post '/v1/objects', headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(422)
      expect(response.body).to eq(errmsg)
    end
  end

  context 'when the SymphonyReader gets an incomplete response' do
    let(:errmsg) { 'my unique snowflake error message' }

    before do
      allow(RegistrationService).to receive(:register_object).and_raise(SymphonyReader::ResponseError.new(errmsg))
    end

    it 'returns a 500 error' do
      post '/v1/objects', headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(500)
      expect(response.body).to eq(errmsg)
    end
  end

  context 'when the object is missing from fedora' do
    let(:errmsg) { 'my unique snowflake error message' }

    before do
      allow(RegistrationService).to receive(:register_object).and_raise(ActiveFedora::ObjectNotFoundError.new(errmsg))
    end

    it 'returns a 404 error' do
      post '/v1/objects', headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(404)
      expect(response.body).to eq(errmsg)
    end
  end

  context 'when the request is successful' do
    before do
      allow(RegistrationService).to receive(:create_from_request).and_return(pid: 'druid:xyz')
    end

    it 'registers the object with the registration service' do
      post '/v1/objects', headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.body).to eq 'druid:xyz'
      expect(RegistrationService).to have_received(:create_from_request)
      expect(response.status).to eq(201)
      expect(response.location).to end_with '/fedora/objects/druid:xyz'
    end
  end
end

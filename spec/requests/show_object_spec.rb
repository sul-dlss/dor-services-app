# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  context 'when the object exists with minimal metadata' do
    before do
      object.descMetadata.title_info.main_title = 'Hello'
      object.label = 'foo'
    end

    it 'returns the object' do
      get '/v1/objects/druid:mk420bs7601',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq '{"externalIdentifier":"druid:1234","type":"object","label":"foo"}'
    end
  end

  context 'when the object exists with full metadata' do
    before do
      object.descMetadata.title_info.main_title = 'Hello'
      object.label = 'foo'
      object.embargoMetadata.release_date = DateTime.parse '2019-09-26T07:00:00Z'
    end

    it 'returns the object' do
      get '/v1/objects/druid:mk420bs7601',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq '{"externalIdentifier":"druid:1234","type":"object","label":"foo",' \
        '"access":{"embargoReleaseDate":"2019-09-26T07:00:00.000+00:00"}}'
    end
  end
end

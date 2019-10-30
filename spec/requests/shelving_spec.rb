# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Shelve object' do
  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(ShelveJob).to receive(:perform_later)
  end

  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  context 'with a collection' do
    let(:object) { Dor::Collection.new(pid: 'druid:1234') }

    it 'returns a 422 error' do
      post '/v1/objects/druid:1234/shelve', headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors'].first['detail']).to eq("A Dor::Item is required but you provided 'Dor::Collection'")
      expect(ShelveJob).not_to have_received(:perform_later)
    end
  end

  context 'when the request is successful' do
    it 'calls ShelvingService and returns201' do
      post '/v1/objects/druid:1234/shelve', headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:created)
      expect(ShelveJob).to have_received(:perform_later)
        .with(druid: 'druid:1234', background_job_result: BackgroundJobResult)
    end
  end
end

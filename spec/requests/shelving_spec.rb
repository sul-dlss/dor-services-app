# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Shelve object' do
  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(ShelvingService).to receive(:shelve)
  end

  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  context 'with a collection' do
    let(:object) { Dor::Collection.new(pid: 'druid:1234') }

    it 'returns a 422 error' do
      post '/v1/objects/druid:1234/shelve', headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors'].first['detail']).to eq("A Dor::Item is required but you provided 'Dor::Collection'")
      expect(ShelvingService).not_to have_received(:shelve)
    end
  end

  context 'when the request is successful' do
    it 'calls ShelvingService and returns 204' do
      post '/v1/objects/druid:1234/shelve', headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:no_content)
      expect(ShelvingService).to have_received(:shelve)
    end
  end

  context "when the file can't be found" do
    before do
      allow(ShelvingService).to receive(:shelve).and_raise(ShelvingService::ContentDirNotFoundError, "file isn't where we looked")
    end

    it 'returns a 422 error' do
      post '/v1/objects/druid:1234/shelve', headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors'].first['detail']).to eq("file isn't where we looked")
    end
  end
end

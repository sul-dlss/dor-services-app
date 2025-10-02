# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Find all objects provided a list of druids' do
  let(:druids) { ['druid:mx123qw2323', 'druid:fp165nz4391', 'druid:bm077td6448'] }
  let(:cocina_objects) { druids.map { |id| build(:dro, id: id) } }

  describe 'POST /v1/objects/find_all' do
    context 'when all druids are found' do
      let(:cocina_objects_without_metadata) { cocina_objects.map { |cocina_object| Cocina::Models.without_metadata(cocina_object) } }

      before do
        allow(CocinaObjectStore).to receive(:find_all).with(druids).and_return(cocina_objects)
      end

      it 'returns a list of all objects' do
        post '/v1/objects/find_all',
             params: { externalIdentifiers: druids }.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to be_an(Array)
        expect(response.parsed_body).to eq(JSON.parse(cocina_objects_without_metadata.to_json))
      end
    end

    context 'when some druids are not found' do
      let(:cocina_objects_without_metadata) do
        [
          Cocina::Models.without_metadata(cocina_objects[0]),
          Cocina::Models.without_metadata(cocina_objects[1])
        ]
      end

      before do
        allow(CocinaObjectStore).to receive(:find_all).with(druids).and_return([cocina_objects[0], cocina_objects[1]])
      end

      it 'returns a list of found objects' do
        post '/v1/objects/find_all',
             params: { externalIdentifiers: druids }.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to be_an(Array)
        expect(response.parsed_body).to eq(JSON.parse(cocina_objects_without_metadata.to_json))
      end
    end

    context 'when all druids are not found' do
      before do
        allow(CocinaObjectStore).to receive(:find_all).with(druids).and_return([])
      end

      it 'returns an empty list' do
        post '/v1/objects/find_all',
             params: { externalIdentifiers: druids }.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to be_an(Array)
        expect(response.parsed_body).to be_empty
      end
    end
  end
end

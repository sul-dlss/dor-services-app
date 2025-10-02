# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Find all objects provided a list of druids' do
  let(:druids) { ['druid:mx123qw2323', 'druid:fp165nz4391', 'druid:bm077td6448'] }
  let(:repository_objects) do
    druids.map do |druid|
      create(:repository_object, :with_repository_object_version,
             external_identifier: druid).head_version.to_cocina_with_metadata
    end
  end

  describe 'POST /v1/objects/find_all' do
    context 'when all druids are found' do
      let(:cocina_objects_with_metadata) do
        repository_objects.map { |cocina_object| Cocina::Models.with_metadata(cocina_object, cocina_object.lock) }
      end

      before do
        allow(CocinaObjectStore).to receive(:find_all).with(druids).and_return(repository_objects)
      end

      it 'returns a list of all objects' do
        post '/v1/objects/find_all',
             params: { externalIdentifiers: druids }.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to be_an(Array)
        expect(response.parsed_body).to eq(JSON.parse(cocina_objects_with_metadata.to_json))
      end
    end

    context 'when some druids are not found' do
      let(:cocina_objects_with_metadata) do
        [
          Cocina::Models.with_metadata(repository_objects[0], repository_objects[0].lock),
          Cocina::Models.with_metadata(repository_objects[1], repository_objects[1].lock)
        ]
      end

      before do
        allow(CocinaObjectStore).to receive(:find_all).with(druids).and_return([repository_objects[0],
                                                                                repository_objects[1]])
      end

      it 'returns a list of found objects' do
        post '/v1/objects/find_all',
             params: { externalIdentifiers: druids }.to_json,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to be_an(Array)
        expect(response.parsed_body).to eq(JSON.parse(cocina_objects_with_metadata.to_json))
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

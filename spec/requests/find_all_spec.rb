# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Find all objects provided a list of druids' do
  let(:druids) { ['druid:mx123qw2323', 'druid:fp165nz4391', 'druid:bm077td6448'] }
  let(:cocina_objects) { druids.map { |id| build(:dro, id: id) } }
  let(:cocina_objects_without_metadata) { cocina_objects.map { |cocina_object| Cocina::Models.without_metadata(cocina_object) } }

  describe 'POST /v1/objects/find_all' do
    before do
      druids.each_with_index do |druid, index|
        allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_objects[index])
      end
    end

    it 'returns a list of objects' do
      post '/v1/objects/find_all',
           params: { externalIdentifiers: druids }.to_json,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to be_an(Array)
      expect(response.parsed_body).to eq(JSON.parse(cocina_objects_without_metadata.to_json))
    end
  end
end

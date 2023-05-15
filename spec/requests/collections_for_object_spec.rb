# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  before do
    allow(CocinaObjectStore).to receive(:find) do |druid|
      found_obj = ([dro] + collections).find { |cocina_obj| cocina_obj.externalIdentifier == druid }
      raise CocinaObjectStore::CocinaObjectNotFoundError if found_obj.blank?

      found_obj
    end
  end

  let(:collection_records) { create_list(:ar_collection, 1) }
  let(:collections) { collection_records.map(&:to_cocina).map { |cocina_object| Cocina::Models.without_metadata(cocina_object) } }

  let(:expected) do
    {
      collections: collections.map(&:to_h)
    }
  end

  let(:dro_record) { create(:ar_dro, isMemberOf: collections.map(&:externalIdentifier)) }
  let(:dro) { dro_record.to_cocina }

  let(:response_model) { response.parsed_body.deep_symbolize_keys }

  describe 'as used by WAS crawl seed registration' do
    it 'returns the JSON used for the collections' do
      get "/v1/objects/#{dro.externalIdentifier}/query/collections",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response_model).to eq expected
    end
  end

  describe 'no collections' do
    let(:collection_records) { [] }

    it 'returns an empty array for collections' do
      get "/v1/objects/#{dro.externalIdentifier}/query/collections",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response_model).to eq expected
    end
  end

  describe 'more than one collection' do
    let(:collection_records) { create_list(:ar_collection, 2) }

    it 'returns an empty array for collections' do
      get "/v1/objects/#{dro.externalIdentifier}/query/collections",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response_model).to eq expected
    end
  end
end

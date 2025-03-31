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

  let(:collection_repository_object_versions) do
    create_list(:repository_object_version, 1, :collection_repository_object_version, :with_repository_object)
  end
  let(:collections) { collection_repository_object_versions.map(&:to_cocina) }

  let(:expected) do
    {
      collections: collections.map(&:to_h)
    }
  end

  let(:dro_record) do
    create(:repository_object, :dro, :with_repository_object_version).tap do |repo_obj|
      repo_obj.head_version.structural['isMemberOf'] = collections.map(&:externalIdentifier)
      repo_obj.head_version.save!
    end
  end
  let(:dro) { dro_record.head_version.to_cocina }

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
    let(:collection_repository_object_versions) do
      create_list(:repository_object_version, 2, :collection_repository_object_version, :with_repository_object)
    end

    it 'returns an empty array for collections' do
      get "/v1/objects/#{dro.externalIdentifier}/query/collections",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response_model).to eq expected
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  let(:object) { instance_double(Dor::Item, collections: [collection]) }
  let(:collection_id) { 'druid:999123' }
  let(:collection) do
    Dor::Collection.new(pid: collection_id, label: 'collection #1')
  end

  let(:expected) do
    {
      collections: [
        {
          externalIdentifier: 'druid:999123',
          type: 'http://cocina.sul.stanford.edu/models/collection.jsonld',
          label: 'collection #1',
          version: 1,
          access: {},
          administrative: {},
          identification: {},
          structural: {}
        }
      ]
    }
  end

  describe 'as used by WAS crawl seed registration' do
    it 'returns (at a minimum) the identifiers of the collections' do
      get '/v1/objects/druid:mk420bs7601/query/collections',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.body).to eq expected.to_json
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show solr for an object' do
  let(:object) { create(:repository_object, :with_repository_object_version, :closed) }

  let(:solr_doc) { { 'id' => object.external_identifier, 'rights_descriptions_ssimdv' => ['world', 'dark (file)'] } }
  let(:indexer) { instance_double(Indexing::Indexers::CompositeIndexer::Instance, to_solr: solr_doc) }

  before do
    allow(Indexing::Builders::DocumentBuilder).to receive(:for).and_return(indexer)
    allow(CocinaObjectStore).to receive(:find).and_call_original
  end

  it 'returns a 200' do
    get "/v1/objects/#{object.external_identifier}/solr?validate=false",
        headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(solr_doc)
    expect(CocinaObjectStore).to have_received(:find).with(object.external_identifier, validate: false)
    expect(Indexing::Builders::DocumentBuilder).to have_received(:for).with(model: an_instance_of(Cocina::Models::DROWithMetadata))
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reindex' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:cocina_object) { instance_double(Cocina::Models::DRO) }

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    allow(Indexer).to receive(:reindex)
  end

  context 'when it is successful' do
    it 'invokes the indexer service' do
      post "/v1/objects/#{druid}/reindex", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:no_content)
      expect(Indexer).to have_received(:reindex).with(cocina_object:)
    end
  end
end

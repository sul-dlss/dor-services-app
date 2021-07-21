# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update DOI metadata' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:object) { Dor::Item.new(pid: druid) }
  let(:cocina_item) do
    instance_double Cocina::Models::DRO, identification: instance_double(Cocina::Models::Identification, doi: '10.0001/mx123qw2323')
  end

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(UpdateDoiMetadataJob).to receive(:perform_later)
    allow(Cocina::Mapper).to receive(:build).and_return(cocina_item)
  end

  context 'when enabled' do
    before do
      allow(Settings.enabled_features).to receive(:datacite_update).and_return(true)
    end

    it 'responds to the request with 202 ("accepted")' do
      post "/v1/objects/#{druid}/update_doi_metadata", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:accepted)
      expect(UpdateDoiMetadataJob).to have_received(:perform_later)
    end
  end

  context 'when disabled (default)' do
    it 'responds to the request with 204 ("no content")' do
      post "/v1/objects/#{druid}/update_doi_metadata", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:no_content)
      expect(UpdateDoiMetadataJob).not_to have_received(:perform_later)
    end
  end
end

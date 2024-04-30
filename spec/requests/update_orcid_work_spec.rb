# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update Orcid work' do
  let(:druid) { object.external_identifier }
  let(:object) do
    create(:repository_object, :with_repository_object_version)
  end

  before do
    allow(UpdateOrcidWorkJob).to receive(:perform_later)
  end

  context 'when enabled' do
    it 'responds to the request with 202 ("accepted")' do
      post "/v1/objects/#{druid}/update_orcid_work", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:accepted)
      expect(UpdateOrcidWorkJob).to have_received(:perform_later).with(String)
    end
  end

  context 'when disabled (default)' do
    before do
      allow(Settings.enabled_features).to receive(:orcid_update).and_return(false)
    end

    it 'responds to the request with 204 ("no content")' do
      post "/v1/objects/#{druid}/update_orcid_work", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:no_content)
      expect(UpdateOrcidWorkJob).not_to have_received(:perform_later)
    end
  end
end

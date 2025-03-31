# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create user version' do
  let(:repository_object) { repository_object_version.repository_object }

  context 'when the user version can be created' do
    let(:repository_object_version) do
      create(:repository_object_version, :with_repository_object, closed_at: Time.zone.now)
    end

    it 'returns created' do
      post "/v1/objects/#{repository_object.external_identifier}/user_versions",
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' },
           params: { version: repository_object_version.version }.to_json

      expect(response).to have_http_status(:created)
      expect(repository_object_version.reload.user_versions.count).to eq(1)
      user_version = repository_object_version.user_versions.first
      expect(response.parsed_body).to eq({ 'userVersion' => user_version.version,
                                           'version' => repository_object_version.version,
                                           'withdrawn' => false, 'withdrawable' => false, 'restorable' => false,
                                           'head' => true })
    end
  end

  context 'when the user version cannot be created' do
    let(:repository_object_version) { create(:repository_object_version, :with_repository_object) }

    it 'returns unprocessable' do
      post "/v1/objects/#{repository_object.external_identifier}/user_versions",
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' },
           params: { version: repository_object_version.version }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      # .parsed_body won't work here because content-type is application/vnd.api+json
      expect(JSON.parse(response.body)).to eq({ errors: [ # rubocop:disable Rails/ResponseParsedBody
        { status: '422', title: 'Unprocessable Content', detail: 'RepositoryObjectVersion not closed' }
      ] }.with_indifferent_access)

      expect(repository_object_version.reload.user_versions.count).to eq(0)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update user version' do
  let(:repository_object) { repository_object_version1.repository_object }
  let(:repository_object_version1) { create(:repository_object_version, :with_repository_object, closed_at: Time.zone.now) }
  let!(:repository_object_version2) { create(:repository_object_version, version: 2, repository_object:, closed_at: Time.zone.now) }
  let(:user_version) { create(:user_version, repository_object_version: repository_object_version1, version: 1) }

  before do
    create(:user_version, repository_object_version: repository_object_version1, version: 2)
  end

  context 'when changing repository object version' do
    it 'updates user version and returns OK' do
      patch "/v1/objects/#{repository_object.external_identifier}/user_versions/#{user_version.version}",
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' },
            params: { version: 2 }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({ 'userVersion' => user_version.version, 'version' => 2, 'withdrawn' => false, 'withdrawable' => true, 'restorable' => false, 'head' => false })

      expect(user_version.reload.repository_object_version).to eq(repository_object_version2)
    end
  end

  context 'when withdrawing' do
    it 'updates user version and returns OK' do
      patch "/v1/objects/#{repository_object.external_identifier}/user_versions/#{user_version.version}",
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' },
            params: { withdrawn: true }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({ 'userVersion' => user_version.version, 'version' => 1, 'withdrawn' => true, 'withdrawable' => false, 'restorable' => true, 'head' => false })

      expect(user_version.reload.withdrawn).to be(true)
    end
  end

  context 'when the user version cannot be updated' do
    before do
      repository_object_version2.update!(closed_at: nil)
    end

    it 'returns unprocessable' do
      patch "/v1/objects/#{repository_object.external_identifier}/user_versions/#{user_version.version}",
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' },
            params: { version: 2 }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      # .parsed_body won't work here because content-type is application/vnd.api+json
      expect(JSON.parse(response.body)).to eq({ errors: [ # rubocop:disable Rails/ResponseParsedBody
        { status: '422', title: 'Unprocessable Content', detail: 'RepositoryObjectVersion not closed' }
      ] }.with_indifferent_access)

      expect(user_version.reload.repository_object_version).to eq(repository_object_version1)
    end
  end
end

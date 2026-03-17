# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show solr for a user version' do
  let(:druid) { 'druid:mx123qw2323' }
  let(:repository_object) do
    create(:repository_object, :with_repository_object_version, :closed, external_identifier: druid)
  end

  before do
    create(:repository_object_version, repository_object:, version: 2, closed_at: Time.zone.now)
    create(:user_version, version: 1, repository_object_version: repository_object.versions.first)
    create(:user_version, version: 2, repository_object_version: repository_object.versions.last)
  end

  it 'returns a 200' do
    get "/v1/objects/#{druid}/user_versions/1",
        headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(type: 'https://cocina.sul.stanford.edu/models/book')
  end

  context 'when found, but stored cocina is invalid' do
    before do
      repository_object.versions.first.update(description: { title: [] })
    end

    it 'returns a 409, and has the json in the meta' do
      get "/v1/objects/#{druid}/user_versions/1",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig('errors', 0, 'title')).to eq 'Object is not valid cocina'
      expect(response.parsed_body.dig('errors', 0, 'meta', 'json', 'type')).to eq 'https://cocina.sul.stanford.edu/models/book'
    end
  end

  context 'when found, but stored cocina is *really* invalid' do
    before do
      repository_object.versions.first.update(
        administrative: {
          hasAdminPolicy: 'druid:hy787xj5878',
          releaseTags: [
            {
              who: 'mjgiarlo',
              what: 'self',
              to: 'Searchworks',
              release: true
            }
          ]
        }
      )
    end

    it 'returns a 409, and has the json in the meta' do
      get "/v1/objects/#{druid}/user_versions/1",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig('errors', 0, 'title')).to eq 'Object is not valid cocina'
      expect(response.parsed_body.dig('errors', 0, 'meta', 'json', 'type')).to eq 'https://cocina.sul.stanford.edu/models/book'
    end
  end
end

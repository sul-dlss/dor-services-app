# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show single object version' do
  let(:druid) { 'druid:mx123qw2323' }

  let(:repository_object) do
    create(:repository_object, :with_repository_object_version, :closed, external_identifier: druid)
  end

  before do
    create(:repository_object_version, repository_object:, version: 2, closed_at: Time.zone.now, cocina_version: nil)
  end

  context 'when found' do
    it 'returns a 200' do
      get "/v1/objects/#{druid}/versions/1",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(type: 'https://cocina.sul.stanford.edu/models/book')
      expect(response.parsed_body).to include(version: 1)
    end
  end

  context 'when found, but stored cocina is invalid' do
    before do
      repository_object.head_version.update(description: '{"title" => []}')
    end

    it 'returns a 409, and has the json in the meta' do
      get "/v1/objects/#{druid}/versions/1",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig('errors', 0, 'title')).to eq 'Object is not valid cocina'
      expect(response.parsed_body.dig('errors', 0, 'meta', 'json', 'type')).to eq 'https://cocina.sul.stanford.edu/models/book'
    end
  end

  context 'when version has no cocina' do
    it 'returns a 400' do
      get "/v1/objects/#{druid}/versions/2",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:bad_request)
    end
  end
end

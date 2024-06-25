# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show single user version' do
  let(:druid) { 'druid:mx123qw2323' }

  context 'when found' do
    before do
      repository_object = create(:repository_object, :with_repository_object_version, :closed, external_identifier: druid)
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
  end
end

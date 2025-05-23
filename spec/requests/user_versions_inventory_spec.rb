# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User versions' do
  let(:druid) { 'druid:mx123qw2323' }

  context 'when found' do
    before do
      repository_object = create(:repository_object, :closed, external_identifier: druid)
      create(:repository_object_version, repository_object:, version: 2, closed_at: Time.zone.now)
      create(:repository_object_version, repository_object:, version: 3, closed_at: Time.zone.now)
      create(:user_version, version: 1, repository_object_version: repository_object.versions[1])
      create(:user_version, version: 2, repository_object_version: repository_object.versions[2])
    end

    it 'returns a 200' do
      get "/v1/objects/#{druid}/user_versions",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq('user_versions' => [
                                           { 'userVersion' => 1, 'version' => 2, 'withdrawn' => false,
                                             'withdrawable' => true, 'restorable' => false, 'head' => false },
                                           { 'userVersion' => 2, 'version' => 3, 'withdrawn' => false,
                                             'withdrawable' => false, 'restorable' => false, 'head' => true }
                                         ])
    end
  end
end

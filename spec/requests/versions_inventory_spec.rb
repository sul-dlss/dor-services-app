# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Versions' do
  let(:druid) { 'druid:mx123qw2323' }

  let(:repository_object) { build(:repository_object, **attrs) }

  let(:attrs) do
    {
      external_identifier: druid,
      object_type: 'dro',
      source_id: 'sul:dlss:testing'
    }
  end

  before do
    repository_object.save # we need at least one persisted version so we can run this test
    repository_object.versions.create!(version: 2, version_description: 'draft',
                                       cocina_version: Cocina::Models::CocinaVersion)
  end

  it 'returns a 200' do
    get "/v1/objects/#{druid}/versions",
        headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq '{"versions":[{"versionId":1,"message":"Initial version","cocina":false},' \
                                '{"versionId":2,"message":"draft","cocina":true}]}'
  end
end

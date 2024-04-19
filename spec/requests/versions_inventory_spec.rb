# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Release tags' do
  let(:druid) { 'druid:mx123qw2323' }

  context 'with an ObjectVersion' do
    before do
      allow(CocinaObjectStore).to receive(:exists!).with(druid)

      ObjectVersion.create(druid:, version: 1, description: 'Initial Version')
      ObjectVersion.create(druid:, version: 2, description: 'pre-assembly re-accession')
      ObjectVersion.create(druid:, version: 3, description: 'pre-assembly re-accession')
    end

    it 'returns a 200' do
      get "/v1/objects/#{druid}/versions",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq '{"versions":[{"versionId":1,"message":"Initial Version"},' \
                                  '{"versionId":2,"message":"pre-assembly re-accession"},' \
                                  '{"versionId":3,"message":"pre-assembly re-accession"}]}'
    end
  end

  context 'with a RepositoryObject' do
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
      repository_object.versions.create!(version: 2, version_description: 'draft')
    end

    it 'returns a 200' do
      get "/v1/objects/#{druid}/versions",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq '{"versions":[{"versionId":1,"message":"Initial version"},' \
                                  '{"versionId":2,"message":"draft"}]}'
    end
  end
end

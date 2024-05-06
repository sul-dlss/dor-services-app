# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update DOI metadata' do
  let(:druid) { 'druid:jh683dj3492' }
  let!(:object) do
    repository_object_version = build(:repository_object_version, external_identifier: druid, identification: {
                                        doi: '10.80343/bc123df4567',
                                        sourceId: "sul:#{rand(100000..9_999_999)}"
                                      })
    create(:repository_object, :with_repository_object_version, repository_object_version:, external_identifier: druid)
  end

  before do
    allow(UpdateDoiMetadataJob).to receive(:perform_later)
  end

  context 'when enabled' do
    before do
      allow(Settings.enabled_features).to receive(:datacite_update).and_return(true)
    end

    context 'when the item meets the required preconditions' do
      before do
        object.head_version.update(
          description: {
            title: [{ value: 'Test obj' }],
            purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}",
            subject: [{ type: 'topic', value: 'word' }],
            contributor: [
              {
                name: [
                  {
                    structuredValue: [
                      {
                        value: 'Jane',
                        type: 'forename'
                      },
                      {
                        value: 'Stanford',
                        type: 'surname'
                      }
                    ]
                  }
                ],
                type: 'person'
              }
            ],
            form: [
              {
                structuredValue: [
                  {
                    value: 'Data',
                    type: 'type'
                  }
                ],
                source: {
                  value: 'Stanford self-deposit resource types'
                },
                type: 'resource type'
              },
              {
                value: 'Dataset',
                type: 'resource type',
                uri: 'http://id.loc.gov/vocabulary/resourceTypes/dat',
                source: {
                  uri: 'http://id.loc.gov/vocabulary/resourceTypes/'
                }
              },
              {
                value: 'Data sets',
                type: 'genre',
                uri: 'https://id.loc.gov/authorities/genreForms/gf2018026119',
                source: {
                  code: 'lcgft'
                }
              },
              {
                value: 'dataset',
                type: 'genre',
                source: {
                  code: 'local'
                }
              },
              {
                value: 'Dataset',
                type: 'resource type',
                source: {
                  value: 'DataCite resource types'
                }
              }
            ]
          }
        )
      end

      it 'responds to the request with 202 ("accepted")' do
        post "/v1/objects/#{druid}/update_doi_metadata", headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:accepted)
        expect(UpdateDoiMetadataJob).to have_received(:perform_later)
      end
    end

    context 'when the item is missing the required preconditions' do
      it 'responds to the request with 409 ("conflict")' do
        post "/v1/objects/#{druid}/update_doi_metadata", headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:conflict)
        expect(UpdateDoiMetadataJob).not_to have_received(:perform_later)
      end
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

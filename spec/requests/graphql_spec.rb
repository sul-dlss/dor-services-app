# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL' do
  let(:query) do
    {
      query:
    <<~GQL
      {
        cocinaObject(externalIdentifier: "#{druid}") {
          externalIdentifier
          type
          cocinaVersion
          label
          description
          geographic
        }
      }
    GQL
    }.to_json
  end

  let(:druid) { cocina_object.external_identifier }
  let(:cocina_version) { cocina_object.cocina_version }
  let(:purl) { "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}" }

  context 'when retrieving a DRO' do
    let(:cocina_object) { create(:ar_dro) }

    it 'returns data' do
      post '/graphql',
           params: query,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.with_indifferent_access).to match(
        {
          data: {
            cocinaObject: {
              externalIdentifier: druid,
              type: 'https://cocina.sul.stanford.edu/models/book',
              cocinaVersion: cocina_version,
              label: 'Test DRO',
              description: {
                purl:,
                title: [{
                  value: 'Test DRO'
                }]
              },
              geographic: nil
            }
          }
        }
      )
    end
  end

  context 'when retrieving a Collection' do
    let(:cocina_object) { create(:ar_collection) }

    it 'returns data' do
      post '/graphql',
           params: query,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.with_indifferent_access).to match(
        {
          data: {
            cocinaObject: {
              externalIdentifier: druid,
              type: 'https://cocina.sul.stanford.edu/models/collection',
              cocinaVersion: cocina_version,
              label: 'Test Collection',
              description: {
                purl:,
                title: [{
                  value: 'Test Collection'
                }]
              },
              geographic: nil
            }
          }
        }
      )
    end
  end

  context 'when retrieving an AdminPolicy' do
    let(:cocina_object) { create(:ar_admin_policy) }

    it 'returns data' do
      post '/graphql',
           params: query,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.with_indifferent_access).to match(
        {
          data: {
            cocinaObject: {
              externalIdentifier: druid,
              type: 'https://cocina.sul.stanford.edu/models/admin_policy',
              cocinaVersion: cocina_version,
              label: 'Test Admin Policy',
              description: nil,
              geographic: nil
            }
          }
        }
      )
    end
  end

  context 'when not found' do
    let(:druid) { 'abc123' }

    it 'returns error' do
      post '/graphql',
           params: query,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.with_indifferent_access).to match(
        {
          data: nil,
          errors: [{
            message: 'Cocina object not found',
            locations: [{
              line: 2,
              column: 3
            }],
            path: ['cocinaObject']
          }]
        }
      )
    end
  end

  context 'without a bearer token' do
    it 'return unauthorized' do
      post '/graphql',
           headers: {}
      expect(response.body).to eq '{"error":"Not Authorized"}'
      expect(response).to be_unauthorized
    end
  end
end

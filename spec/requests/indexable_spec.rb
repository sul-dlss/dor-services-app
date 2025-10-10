# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Indexable' do
  let!(:item) { create(:repository_object, :with_repository_object_version, version: 1) }
  let(:druid) { item.external_identifier }
  let(:purl) { "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}" }
  let(:apo) do
    create(:repository_object, :admin_policy, :with_repository_object_version)
  end
  let(:apo_druid) { apo.external_identifier }
  let(:label) { 'This is my label' }
  let(:title) { 'This is my title' }
  let(:who) { 'test_user' }

  let(:view) { 'world' }
  let(:download) { 'world' }
  let(:description) do
    {
      title: [{ value: title }],
      purl: "https://purl.stanford.edu/#{item.external_identifier.delete_prefix('druid:')}",
      contributor: [{
        name: [{
          parallelValue: contributor_name_parallel
        }]
      }]
    }
  end
  let(:contributor_name_parallel) { [first_parallel_name, second_parallel_name] }
  let(:first_parallel_name) do
    {
      value: 'Invalid parallel value name',
      type: 'transliteration',
      standard: {
        value: 'Invalid parallel standard value'
      },
      valueLanguage: {
        code: 'eng',
        uri: 'https://id.loc.gov/vocabulary/iso639-2/eng',
        source: {
          code: 'iso632-2b'
        },
        valueScript: {
          code: 'Latn',
          source: {
            code: 'iso15924'
          }
        }
      }
    }
  end
  let(:second_parallel_name) do
    {
      value: 'Valid second parallel value name',
      status: 'primary',
      standard: {
        value: 'Valid second parallel standard value'
      },
      valueLanguage: {
        code: 'eng',
        uri: 'https://id.loc.gov/vocabulary/iso639-2/eng',
        source: {
          code: 'iso632-2b'
        },
        valueScript: {
          code: 'Latn',
          source: {
            code: 'iso15924'
          }
        }
      }
    }
  end
  let(:content_type) { Cocina::Models::ObjectType.book }
  let(:data) do
    <<~JSON
      {
        "user_name": "#{who}",
        "cocinaVersion": "#{Cocina::Models::VERSION}",
        "externalIdentifier": "#{druid}",
        "type":"#{content_type}",
        "label":"#{label}","version":1,
        "access":{
          "view":"#{view}",
          "download":"#{view}",
          "copyright":"All rights reserved unless otherwise indicated.",
          "useAndReproductionStatement":"Property rights reside with the repository..."
        },
        "administrative":{"hasAdminPolicy":"#{apo_druid}"},
        "description":#{description.to_json},
        "identification":#{identification.to_json},
        "structural":{
            "hasMemberOrders":[{"viewingDirection":"right-to-left"}],
            "isMemberOf":["druid:xx888xx7777"]
          }
      }
    JSON
  end
  let(:identification) do
    {
      sourceId: 'googlebooks:999999',
      barcode: '36105036289127',
      doi: '10.25740/gg777gg7777'
    }
  end

  let(:headers) do
    {
      'Authorization' => "Bearer #{jwt}",
      'Content-Type' => 'application/json'
    }
  end

  context 'when a dro is provided' do
    context 'when the descriptive metadata can be indexed' do
      it 'returns a 204 - no content' do
        post("/v1/objects/#{druid}/indexable",
             params: data,
             headers:)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when the descriptive metadata can not be index' do
      let(:contributor_name_parallel) { [first_parallel_name] }

      it 'returns a 412 - index validation failed' do
        post("/v1/objects/#{druid}/indexable",
             params: data,
             headers:)
        expect(response).to have_http_status(:precondition_failed)
        expect(response.body).to include("undefined method 'valueLanguage' for an instance of Array")
      end
    end
  end
end

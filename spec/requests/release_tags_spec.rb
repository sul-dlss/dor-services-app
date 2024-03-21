# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Operations on release tags' do
  let(:tag) do
    Cocina::Models::ReleaseTag.new(
      to: 'Searchworks',
      what: 'self',
      date: '2014-08-30T01:06:28.000+00:00',
      who: 'petucket',
      release: true
    )
  end
  let(:auth_headers) { { 'Authorization' => "Bearer #{jwt}" } }
  let(:lock) { 'abc123' }
  let(:druid) { 'druid:mx123qw2323' }

  let(:cocina_object_with_metadata) do
    Cocina::Models.with_metadata(cocina_object, lock)
  end

  before do
    allow(CocinaObjectStore).to receive_messages(find: cocina_object_with_metadata)
  end

  describe '#index' do
    let(:cocina_object) do
      build(:dro, id: druid).new(
        administrative: {
          hasAdminPolicy: 'druid:hy787xj5878',
          releaseTags: [tag]
        }
      )
    end

    it 'returns the latest version for an object' do
      get "/v1/objects/#{druid}/release_tags", headers: auth_headers

      expect(response.parsed_body).to contain_exactly(tag.to_h.stringify_keys)
    end
  end

  describe '#create' do
    let(:cocina_object) do
      build(:dro, id: druid)
    end

    context 'when succeessful' do
      let(:data) do
        tag.to_json
      end

      it 'creates a tag' do
        post "/v1/objects/#{druid}/release_tags",
             headers: auth_headers.merge('Content-Type' => 'application/json'),
             params: data
        expect(response).to have_http_status :created
      end
    end
  end
end

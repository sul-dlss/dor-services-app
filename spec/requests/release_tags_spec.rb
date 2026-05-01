# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Operations on release tags' do
  let(:auth_headers) { { 'Authorization' => "Bearer #{jwt}" } }
  let(:cocina_object) { build(object_type, id: druid) }
  let(:cocina_object_with_metadata) { Cocina::Models.with_metadata(cocina_object, 'abc123') }
  let(:collection) { build(:collection) }
  let!(:collection_tag) do
    ReleaseTag.create!(druid: collection.externalIdentifier, who: 'petucket', what: 'collection',
                       released_to: 'PURL Sitemap', release: true)
              .to_cocina
  end
  let(:druid) { 'druid:mx123qw2323' }
  let(:object_type) { :dro }
  let(:tag) do
    Dor::ReleaseTag.new(
      to: 'Searchworks',
      what: 'self',
      date: '2014-08-30T01:06:28.000+00:00',
      who: 'petucket',
      release: true
    )
  end

  before do
    allow(CocinaObjectStore).to receive_messages(find: cocina_object_with_metadata)
  end

  describe '#index' do
    before { ReleaseTag.from_cocina(druid:, tag:).save! }

    it 'returns the release tags' do
      get "/v1/objects/#{druid}/release_tags", headers: auth_headers

      expect(response.parsed_body).to contain_exactly(tag.to_h.stringify_keys)
    end

    context 'with public flag turned off' do
      it 'returns the release tags' do
        get "/v1/objects/#{druid}/release_tags?public=false", headers: auth_headers

        expect(response.parsed_body).to contain_exactly(tag.to_h.stringify_keys)
      end
    end

    context 'with public tags requested' do
      let(:cocina_object) do
        build(object_type, id: druid).new(structural: { isMemberOf: [collection.externalIdentifier] })
      end

      it 'returns the release tags' do
        get "/v1/objects/#{druid}/release_tags?public=true", headers: auth_headers

        expect(response.parsed_body).to contain_exactly(collection_tag.to_h.stringify_keys, tag.to_h.stringify_keys)
      end
    end

    context 'when an AdminPolicy' do
      let(:object_type) { :admin_policy }

      it 'returns unprocessable entity' do
        get "/v1/objects/#{druid}/release_tags", headers: auth_headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe '#create' do
    let(:data) { tag.to_json }

    before { allow(ReleaseTagService).to receive(:create) }

    it 'creates a tag' do
      post "/v1/objects/#{druid}/release_tags?lane-id=low",
           headers: auth_headers.merge('Content-Type' => 'application/json'),
           params: data
      expect(response).to have_http_status :created
      expect(ReleaseTagService).to have_received(:create).with(cocina_object: cocina_object_with_metadata,
                                                               tag: an_instance_of(Dor::ReleaseTag), lane_id: :low)
    end
  end
end

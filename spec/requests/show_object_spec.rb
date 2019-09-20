# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  context 'when the requested object is an item' do
    let(:object) { Dor::Item.new(pid: 'druid:1234') }

    context 'when the object exists with minimal metadata' do
      before do
        object.descMetadata.title_info.main_title = 'Hello'
        object.label = 'foo'
      end

      let(:expected) do
        {
          externalIdentifier: 'druid:1234',
          type: 'object',
          label: 'foo',
          version: 1,
          access: {},
          administrative: {
            releaseTags: []
          },
          identification: {},
          structural: {}
        }
      end

      it 'returns the object' do
        get '/v1/objects/druid:mk420bs7601',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq expected.to_json
      end
    end

    context 'when the object exists with full metadata' do
      before do
        object.descMetadata.title_info.main_title = 'Hello'
        object.label = 'foo'
        object.embargoMetadata.release_date = DateTime.parse '2019-09-26T07:00:00Z'
        ReleaseTags.create(object, release: true,
                                   what: 'self',
                                   to: 'Searchworks',
                                   who: 'petucket',
                                   when: '2014-08-30T01:06:28Z')
      end

      let(:expected) do
        {
          externalIdentifier: 'druid:1234',
          type: 'object',
          label: 'foo',
          version: 1,
          access: {
            embargoReleaseDate: '2019-09-26T07:00:00.000+00:00'
          },
          administrative: {
            releaseTags: [
              {
                to: 'Searchworks',
                what: 'self',
                date: '2014-08-30T01:06:28.000+00:00',
                who: 'petucket',
                release: true
              }
            ]
          },
          identification: {},
          structural: {}
        }
      end

      it 'returns the object' do
        get '/v1/objects/druid:mk420bs7601',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq expected.to_json
      end
    end
  end

  context 'when the requested object is an APO' do
    let(:object) { Dor::AdminPolicyObject.new(pid: 'druid:1234') }

    context 'when the object exists with minimal metadata' do
      before do
        object.descMetadata.title_info.main_title = 'Hello'
        object.label = 'foo'
      end

      let(:expected) do
        {
          externalIdentifier: 'druid:1234',
          type: 'admin_policy',
          label: 'foo',
          version: 1,
          access: {},
          administrative: {},
          identification: {},
          structural: {}
        }
      end

      it 'returns the object' do
        get '/v1/objects/druid:mk420bs7601',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq expected.to_json
      end
    end
  end
end

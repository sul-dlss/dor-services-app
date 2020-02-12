# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  before do
    allow(Dor).to receive(:find).and_return(object)
  end

  context 'when the requested object is an item' do
    let(:object) { Dor::Item.new(pid: 'druid:1234', source_id: 'src:99999', label: 'foo') }

    context 'when the object exists with minimal metadata' do
      before do
        object.descMetadata.title_info.main_title = 'Hello'
      end

      let(:expected) do
        {
          externalIdentifier: 'druid:1234',
          type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
          label: 'foo',
          version: 1,
          access: {},
          administrative: {
            releaseTags: [],
            hasAdminPolicy: nil
          },
          description: {
            title: [
              { primary: true,
                titleFull: 'Hello' }
            ]
          },
          identification: {
            sourceId: 'src:99999'
          },
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
          type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
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
            ],
            hasAdminPolicy: nil
          },
          description: {
            title: [
              { primary: true,
                titleFull: 'Hello' }
            ]
          },
          identification: {
            sourceId: 'src:99999'
          },
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
        allow(object).to receive(:admin_policy_object_id).and_return('druid:ab123cd4567')
      end

      it 'returns the object' do
        get '/v1/objects/druid:mk420bs7601',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['externalIdentifier']).to eq 'druid:1234'
        expect(json['type']).to eq 'http://cocina.sul.stanford.edu/models/admin_policy.jsonld'
        expect(json['label']).to eq 'foo'
        expect(json['version']).to eq 1
        expect(json['access']).to eq({})
        expect(json['identification']).to eq({})
        expect(json['structural']).to eq({})
        expect(json['administrative']['default_object_rights']).to match '<rightsMetadata>'
        expect(json['administrative']['registration_workflow']).to be_nil
        expect(json['administrative']['hasAdminPolicy']).to eq 'druid:ab123cd4567'
      end
    end

    context 'when the object exists with all metadata' do
      before do
        object.administrativeMetadata.content = <<~XML
          <administrativeMetadata>
            <dissemination>
              <workflow id="wasCrawlPreassemblyWF"/>
            </dissemination>
          </administrativeMetadata>
        XML
        object.descMetadata.title_info.main_title = 'Hello'
        object.label = 'foo'
      end

      it 'returns the object' do
        get '/v1/objects/druid:mk420bs7601',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['externalIdentifier']).to eq 'druid:1234'
        expect(json['type']).to eq 'http://cocina.sul.stanford.edu/models/admin_policy.jsonld'
        expect(json['label']).to eq 'foo'
        expect(json['version']).to eq 1
        expect(json['access']).to eq({})
        expect(json['identification']).to eq({})
        expect(json['structural']).to eq({})
        expect(json['administrative']['default_object_rights']).to match '<rightsMetadata>'
        expect(json['administrative']['registration_workflow']).to eq 'wasCrawlPreassemblyWF'
      end
    end
  end
end

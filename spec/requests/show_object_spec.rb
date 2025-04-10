# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  let(:druid) { object.external_identifier }
  let(:purl) { "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}" }

  context 'when the requested object is an item' do
    let(:response_model) { response.parsed_body.deep_symbolize_keys }
    let(:object) do
      create(:repository_object, :with_repository_object_version, source_id: 'googlebooks:d1', version: 1)
    end

    context 'when the object exists with full metadata' do
      let(:expected) do
        Cocina::Models::DRO.new(
          {
            externalIdentifier: druid,
            type: Cocina::Models::ObjectType.object,
            label: 'foo',
            version: 1,
            access: {
              view: 'world',
              copyright: 'All rights reserved unless otherwise indicated.',
              download: 'world',
              embargo: {
                releaseDate: '2019-09-26T07:00:00.000+00:00',
                view: 'world',
                download: 'world'
              },
              useAndReproductionStatement: 'Property rights reside with the repository...'
            },
            administrative: {
              hasAdminPolicy: 'druid:df123cd4567'
            },
            description: {
              title: [
                { value: 'Hello' }
              ],
              purl:
            },
            identification: {
              sourceId: 'src:99999'
            },
            structural: {
              isMemberOf: ['druid:xx888xx7777']
            }
          }
        )
      end

      before do
        object.head_version.update(
          content_type: Cocina::Models::ObjectType.object,
          label: 'foo',
          version: 1,
          access: {
            view: 'world',
            copyright: 'All rights reserved unless otherwise indicated.',
            download: 'world',
            embargo: {
              releaseDate: '2019-09-26T07:00:00.000+00:00',
              view: 'world',
              download: 'world'
            },
            useAndReproductionStatement: 'Property rights reside with the repository...'
          },
          administrative: {
            hasAdminPolicy: 'druid:df123cd4567'
          },
          description: {
            title: [
              { value: 'Hello' }
            ],
            purl:
          },
          identification: {
            sourceId: 'src:99999'
          },
          structural: {
            isMemberOf: ['druid:xx888xx7777']
          }
        )
      end

      it 'returns the object' do
        get "/v1/objects/#{druid}",
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.headers['Last-Modified']).to end_with 'GMT'
        expect(response.headers['X-Created-At']).to end_with 'GMT'
        expect(response.headers['ETag']).to match(%r{W/".+"})
        expect(response.body).to equal_cocina_model(expected)
      end
    end

    context 'when the object is a virtual object' do
      before do
        object.head_version.update(structural: { hasMemberOrders: [{
                                     members: [
                                       'druid:kq126jw7402',
                                       'druid:cv761kr7119',
                                       'druid:kn300wd1779',
                                       'druid:rz617vr4473',
                                       'druid:sd322dt2118',
                                       'druid:hp623ch4433',
                                       'druid:sq217qj5005',
                                       'druid:vd823mb5658',
                                       'druid:zp230ft8517',
                                       'druid:xx933wk5286',
                                       'druid:qf828rv2163'
                                     ]
                                   }] })
      end

      it 'returns the object' do
        get "/v1/objects/#{druid}",
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to equal_cocina_model(object.head_version.to_cocina)
      end
    end

    context 'when the object has not changed and If-None-Match provided' do
      it 'returns not modified' do
        get "/v1/objects/#{druid}",
            headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status(:ok)

        get "/v1/objects/#{druid}",
            headers: {
              'Authorization' => "Bearer #{jwt}",
              # This is testing -gzip stripping.
              'If-None-Match' => response.headers['ETag'].sub(/"$/, '-gzip"')
            }
        expect(response).to have_http_status(:not_modified)
      end
    end

    context 'when the object has changed and If-None-Match provided' do
      it 'returns the object' do
        get "/v1/objects/#{druid}",
            headers: {
              'Authorization' => "Bearer #{jwt}",
              'If-None-Match' => 'wrong etag'
            }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context 'when the requested object is a collection' do
    let(:object) { create(:repository_object, :collection, :with_repository_object_version) }

    it 'returns the object' do
      get "/v1/objects/#{druid}",
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to equal_cocina_model(object.head_version.to_cocina)
    end
  end

  context 'when the requested object is an APO' do
    let(:druid) { 'druid:mf309wt4240' }

    before do
      repository_object_version = build(:repository_object_version, :admin_policy_repository_object_version,
                                        external_identifier: druid, version: 1, administrative: {
                                          registrationWorkflow: %w[registrationWF goobiWF],
                                          disseminationWorkflow: 'wasCrawlPreassemblyWF',
                                          hasAdminPolicy: 'druid:bc123df4567',
                                          hasAgreement: 'druid:bb008zm4587',
                                          accessTemplate: {},
                                          roles: [
                                            {
                                              'name' => 'dor-apo-manager',
                                              'members' => [
                                                {
                                                  'type' => 'workgroup',
                                                  'identifier' => 'sdr:psm-staff'
                                                },
                                                {
                                                  'type' => 'workgroup',
                                                  'identifier' => 'sdr:developer'
                                                },
                                                {
                                                  'type' => 'workgroup',
                                                  'identifier' => 'sdr:metadata-staff'
                                                },
                                                {
                                                  'type' => 'workgroup',
                                                  'identifier' => 'sdr:admin-docs'
                                                }
                                              ]
                                            }
                                          ]
                                        })
      create(:repository_object, :admin_policy, :with_repository_object_version, repository_object_version:,
                                                                                 external_identifier: druid)
    end

    context 'when the object exists with all metadata' do
      it 'returns the object' do
        get "/v1/objects/#{druid}",
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        json = response.parsed_body

        expect(json['type']).to eq Cocina::Models::ObjectType.admin_policy
        expect(json['label']).to eq 'Test Admin Policy'
        expect(json['version']).to eq 1
        expect(json['administrative']['registrationWorkflow']).to eq %w[registrationWF goobiWF]
        expect(json['administrative']['disseminationWorkflow']).to eq 'wasCrawlPreassemblyWF'
        expect(json['administrative']['roles']).to eq [
          {
            'name' => 'dor-apo-manager',
            'members' => [
              {
                'type' => 'workgroup',
                'identifier' => 'sdr:psm-staff'
              },
              {
                'type' => 'workgroup',
                'identifier' => 'sdr:developer'
              },
              {
                'type' => 'workgroup',
                'identifier' => 'sdr:metadata-staff'
              },
              {
                'type' => 'workgroup',
                'identifier' => 'sdr:admin-docs'
              }
            ]
          }
        ]
      end
    end
  end
end

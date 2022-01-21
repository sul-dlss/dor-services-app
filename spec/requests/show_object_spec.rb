# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get the object' do
  before do
    allow(Dor).to receive(:find).and_return(object)
    # When an AF object comes from persistence, then modified_date is a string.  If it's new it's a date.
    # So by mocking this as a string it looks like the real use case:
    allow(object).to receive(:createdDate).and_return('2022-01-20T14:50:08.107Z')
    allow(object).to receive(:modified_date).and_return('2021-03-04T14:50:08.107Z')
    allow(object).to receive(:admin_policy_object_id).and_return('druid:df123cd4567')
  end

  context 'when the requested object is an item' do
    let(:object) do
      Dor::Item.new(pid: 'druid:bc123df4567',
                    source_id: 'src:99999',
                    label: 'foo',
                    read_rights: 'world').tap do |i|
        i.rightsMetadata.copyright = 'All rights reserved unless otherwise indicated.'
        i.rightsMetadata.use_statement = 'Property rights reside with the repository...'
        i.descMetadata.title_info.main_title = 'Hello'
      end
    end

    let(:response_model) { JSON.parse(response.body).deep_symbolize_keys }

    context 'when the object exists with minimal metadata' do
      let(:expected) do
        Cocina::Models::DRO.new(
          {
            externalIdentifier: 'druid:bc123df4567',
            type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
            label: 'foo',
            version: 1,
            access: {
              access: 'world',
              copyright: 'All rights reserved unless otherwise indicated.',
              download: 'world',
              useAndReproductionStatement: 'Property rights reside with the repository...'
            },
            administrative: {
              hasAdminPolicy: 'druid:df123cd4567'
            },
            description: {
              title: [
                { value: 'Hello' }
              ],
              purl: 'https://purl.stanford.edu/bc123df4567',
              access: {
                digitalRepository: [
                  { value: 'Stanford Digital Repository' }
                ]
              }
            },
            identification: {
              sourceId: 'src:99999'
            },
            structural: {}
          }
        )
      end

      it 'returns the object' do
        get '/v1/objects/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.headers['Last-Modified']).to end_with 'GMT'
        expect(response.headers['X-Created-At']).to end_with 'GMT'
        expect(response.body).to equal_cocina_model(expected)
      end
    end

    context 'when the object exists with full metadata' do
      before do
        allow(object).to receive(:collections).and_return([collection])

        embargo = Cocina::Models::Embargo.new(releaseDate: DateTime.parse('2019-09-26T07:00:00Z'), access: 'world', download: 'world')
        Cocina::ToFedora::EmbargoMetadataGenerator.generate(embargo_metadata: object.embargoMetadata, embargo: embargo)
        ReleaseTags.create(object, release: true,
                                   what: 'self',
                                   to: 'Searchworks',
                                   who: 'petucket',
                                   when: '2014-08-30T01:06:28Z')
      end

      let(:collection) { Dor::Collection.new(pid: 'druid:xx888xx7777') }

      let(:expected) do
        Cocina::Models::DRO.new(
          {
            externalIdentifier: 'druid:bc123df4567',
            type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
            label: 'foo',
            version: 1,
            access: {
              access: 'world',
              copyright: 'All rights reserved unless otherwise indicated.',
              download: 'world',
              embargo: {
                releaseDate: '2019-09-26T07:00:00.000+00:00',
                access: 'world',
                download: 'world'
              },
              useAndReproductionStatement: 'Property rights reside with the repository...'
            },
            administrative: {
              hasAdminPolicy: 'druid:df123cd4567',
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
            description: {
              title: [
                { value: 'Hello' }
              ],
              purl: 'https://purl.stanford.edu/bc123df4567',
              access: {
                digitalRepository: [
                  { value: 'Stanford Digital Repository' }
                ]
              }
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

      it 'returns the object' do
        get '/v1/objects/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to equal_cocina_model(expected)
      end
    end

    context 'when the object has a released embargo' do
      before do
        embargo = Cocina::Models::Embargo.new(releaseDate: DateTime.parse('2019-09-26T07:00:00Z'), access: 'world', download: 'world')
        Cocina::ToFedora::EmbargoMetadataGenerator.generate(embargo_metadata: object.embargoMetadata, embargo: embargo)
        object.embargoMetadata.status = 'released'
      end

      let(:expected) do
        Cocina::Models::DRO.new({
                                  externalIdentifier: 'druid:bc123df4567',
                                  type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
                                  label: 'foo',
                                  version: 1,
                                  access: {
                                    access: 'world',
                                    copyright: 'All rights reserved unless otherwise indicated.',
                                    download: 'world',
                                    useAndReproductionStatement: 'Property rights reside with the repository...'
                                  },
                                  administrative: {
                                    hasAdminPolicy: 'druid:df123cd4567'
                                  },
                                  description: {
                                    title: [
                                      { value: 'Hello' }
                                    ],
                                    purl: 'https://purl.stanford.edu/bc123df4567',
                                    access: {
                                      digitalRepository: [
                                        { value: 'Stanford Digital Repository' }
                                      ]
                                    }
                                  },
                                  identification: {
                                    sourceId: 'src:99999'
                                  },
                                  structural: {}
                                })
      end

      it 'returns the object without the embargo' do
        get '/v1/objects/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to equal_cocina_model(expected)
      end
    end

    context 'when the object is a virtual object' do
      before do
        object.contentMetadata.content = <<~XML
          <contentMetadata objectId="cp799hh4428" type="image">
            <resource id="cp799hh4428_1" sequence="1" type="image">
              <externalFile fileId="1592A.jp2" mimetype="image/jp2" objectId="druid:kq126jw7402" resourceId="kq126jw7402_1"/>
              <relationship objectId="druid:kq126jw7402" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_2" sequence="2" type="image">
              <externalFile fileId="1592B.jp2" mimetype="image/jp2" objectId="druid:cv761kr7119" resourceId="cv761kr7119_1"/>
              <relationship objectId="druid:cv761kr7119" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_3" sequence="3" type="image">
              <externalFile fileId="1592c.jp2" mimetype="image/jp2" objectId="druid:kn300wd1779" resourceId="kn300wd1779_1"/>
              <relationship objectId="druid:kn300wd1779" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_4" sequence="4" type="image">
              <externalFile fileId="1592001.jp2" mimetype="image/jp2" objectId="druid:rz617vr4473" resourceId="rz617vr4473_1"/>
              <relationship objectId="druid:rz617vr4473" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_5" sequence="5" type="image">
              <externalFile fileId="1592002.jp2" mimetype="image/jp2" objectId="druid:sd322dt2118" resourceId="sd322dt2118_1"/>
              <relationship objectId="druid:sd322dt2118" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_6" sequence="6" type="image">
              <externalFile fileId="1592003.jp2" mimetype="image/jp2" objectId="druid:hp623ch4433" resourceId="hp623ch4433_1"/>
              <relationship objectId="druid:hp623ch4433" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_7" sequence="7" type="image">
              <externalFile fileId="1592004.jp2" mimetype="image/jp2" objectId="druid:sq217qj5005" resourceId="sq217qj5005_1"/>
              <relationship objectId="druid:sq217qj5005" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_8" sequence="8" type="image">
              <externalFile fileId="1592005.jp2" mimetype="image/jp2" objectId="druid:vd823mb5658" resourceId="vd823mb5658_1"/>
              <relationship objectId="druid:vd823mb5658" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_9" sequence="9" type="image">
              <externalFile fileId="1592006.jp2" mimetype="image/jp2" objectId="druid:zp230ft8517" resourceId="zp230ft8517_1"/>
              <relationship objectId="druid:zp230ft8517" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_10" sequence="10" type="image">
              <externalFile fileId="1592007.jp2" mimetype="image/jp2" objectId="druid:xx933wk5286" resourceId="xx933wk5286_1"/>
              <relationship objectId="druid:xx933wk5286" type="alsoAvailableAs"/>
            </resource>
            <resource id="cp799hh4428_11" sequence="11" type="image">
              <externalFile fileId="1592008.jp2" mimetype="image/jp2" objectId="druid:qf828rv2163" resourceId="qf828rv2163_1"/>
              <relationship objectId="druid:qf828rv2163" type="alsoAvailableAs"/>
            </resource>
          </contentMetadata>
        XML

        allow(object).to receive(:collection_ids).and_return([])
      end

      let(:expected) do
        Cocina::Models::DRO.new({
                                  externalIdentifier: 'druid:bc123df4567',
                                  type: 'http://cocina.sul.stanford.edu/models/image.jsonld',
                                  label: 'foo',
                                  version: 1,
                                  access: {
                                    access: 'world',
                                    copyright: 'All rights reserved unless otherwise indicated.',
                                    download: 'world',
                                    useAndReproductionStatement: 'Property rights reside with the repository...'
                                  },
                                  administrative: {
                                    hasAdminPolicy: 'druid:df123cd4567'
                                  },
                                  description: {
                                    title: [
                                      { value: 'Hello' }
                                    ],
                                    purl: 'https://purl.stanford.edu/bc123df4567',
                                    access: {
                                      digitalRepository: [
                                        { value: 'Stanford Digital Repository' }
                                      ]
                                    }
                                  },
                                  identification: {
                                    sourceId: 'src:99999'
                                  },
                                  structural: {
                                    hasMemberOrders: [
                                      {
                                        members: [
                                          'kq126jw7402_1/1592A.jp2',
                                          'cv761kr7119_1/1592B.jp2',
                                          'kn300wd1779_1/1592c.jp2',
                                          'rz617vr4473_1/1592001.jp2',
                                          'sd322dt2118_1/1592002.jp2',
                                          'hp623ch4433_1/1592003.jp2',
                                          'sq217qj5005_1/1592004.jp2',
                                          'vd823mb5658_1/1592005.jp2',
                                          'zp230ft8517_1/1592006.jp2',
                                          'xx933wk5286_1/1592007.jp2',
                                          'qf828rv2163_1/1592008.jp2'
                                        ]
                                      }
                                    ]
                                  }
                                })
      end

      it 'returns the object' do
        get '/v1/objects/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to equal_cocina_model(expected)
      end
    end

    context 'when the object exists without a sourceId' do
      let(:object) do
        Dor::Item.new(pid: 'druid:bc123df4567',
                      label: 'foo',
                      read_rights: 'world').tap do |i|
          i.rightsMetadata.copyright = 'All rights reserved unless otherwise indicated.'
          i.rightsMetadata.use_statement = 'Property rights reside with the repository...'
          i.descMetadata.title_info.main_title = 'Hello'
        end
      end

      let(:expected) do
        {
          errors: [
            a_hash_including(
              detail: 'unable to resolve a sourceId for druid:bc123df4567',
              meta: { backtrace: include(match("app/services/cocina/mapper.rb:[0-9]+:in `build'$")) },
              status: '422',
              title: 'Unexpected Cocina::Mapper.build error'
            )
          ]
        }
      end

      it 'returns the error' do
        get '/v1/objects/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_model).to include expected
      end
    end

    context 'when there is an unexpected error mapping properties from the Fedora representation' do
      let(:object) do
        Dor::Item.new(pid: 'druid:bc123df4567',
                      source_id: 'src:99999',
                      label: 'foo',
                      read_rights: 'world').tap do |i|
          i.descMetadata.content = xml
        end
      end
      let(:xml) do
        <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title>journal of stuff (2)</title>
            </titleInfo>
          </mods>
        XML
      end

      let(:expected) do
        {
          errors: [
            a_hash_including({ detail: 'key not found: nil',
                               meta: { backtrace: include(match("app/services/cocina/mapper.rb:[0-9]+:in `build'$")) },
                               status: '422',
                               title: 'Unexpected Cocina::Mapper.build error' })
          ]
        }
      end

      before { allow(Cocina::FromFedora::DRO).to receive(:props).and_raise(KeyError, 'key not found: nil') }

      it 'returns the error' do
        get '/v1/objects/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_model).to include(expected)
      end
    end

    context 'when there is a solr error' do
      before do
        allow(Cocina::Mapper).to receive(:build).and_raise(SolrConnectionError, 'broken')
      end

      let(:expected) do
        {
          errors: [{ detail: 'broken', status: '500', title: 'Unable to reach Solr' }]
        }
      end

      it 'returns the error' do
        get '/v1/objects/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:internal_server_error)
        expect(response_model).to eq expected
      end
    end
  end

  context 'when the requested object is an collection' do
    before do
      object.descMetadata.title_info.main_title = 'Hello'
    end

    let(:object) do
      Dor::Collection.new(pid: 'druid:bc123df4567',
                          label: 'foo',
                          read_rights: 'world')
    end

    let(:expected) do
      Cocina::Models::Collection.new(
        externalIdentifier: 'druid:bc123df4567',
        type: 'http://cocina.sul.stanford.edu/models/collection.jsonld',
        label: 'foo',
        version: 1,
        access: {
          access: 'world'
        },
        administrative: {
          hasAdminPolicy: 'druid:df123cd4567'
        },
        description: {
          title: [
            { value: 'Hello' }
          ],
          purl: 'https://purl.stanford.edu/bc123df4567',
          access: {
            digitalRepository: [
              { value: 'Stanford Digital Repository' }
            ]
          }
        }
      )
    end

    it 'returns the object' do
      get '/v1/objects/druid:bc123df4567',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to equal_cocina_model(expected)
    end
  end

  context 'when the requested object is an APO' do
    let(:object) { Dor::AdminPolicyObject.new(pid: 'druid:bc123df4567') }

    context 'when the object exists with minimal metadata' do
      before do
        object.descMetadata.title_info.main_title = 'Hello'
        object.label = 'foo'
      end

      it 'returns the object' do
        get '/v1/objects/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['externalIdentifier']).to eq 'druid:bc123df4567'
        expect(json['type']).to eq 'http://cocina.sul.stanford.edu/models/admin_policy.jsonld'
        expect(json['label']).to eq 'foo'
        expect(json['version']).to eq 1
        expect(json['administrative']['defaultObjectRights']).to match '<rightsMetadata>'
        expect(json['administrative']['registrationWorkflow']).to eq []
        expect(json['administrative']['hasAdminPolicy']).to eq 'druid:df123cd4567'
        expect(json['administrative']['roles']).to eq []
      end
    end

    context 'when the object exists with all metadata' do
      before do
        object.administrativeMetadata.content = <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="registrationWF"/>
              <workflow id="goobiWF"/>
            </registration>
            <dissemination>
              <workflow id="wasCrawlPreassemblyWF"/>
            </dissemination>
          </administrativeMetadata>
        XML
        object.roleMetadata.content = <<~XML
          <roleMetadata objectId="druid:bx911tp9024">
            <role type="dor-apo-manager">
              <group>
                <identifier type="workgroup">sdr:psm-staff</identifier>
              </group>
              <group>
                <identifier type="workgroup">sdr:developer</identifier>
              </group>
              <group>
                <identifier type="workgroup">sdr:metadata-staff</identifier>
              </group>
              <group>
                <identifier type="workgroup">sdr:admin-docs</identifier>
              </group>
            </role>
          </roleMetadata>
        XML
        object.descMetadata.title_info.main_title = 'Hello'
        object.label = 'foo'
      end

      it 'returns the object' do
        get '/v1/objects/druid:bc123df4567',
            headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['externalIdentifier']).to eq 'druid:bc123df4567'
        expect(json['type']).to eq 'http://cocina.sul.stanford.edu/models/admin_policy.jsonld'
        expect(json['label']).to eq 'foo'
        expect(json['version']).to eq 1
        expect(json['administrative']['defaultObjectRights']).to match '<rightsMetadata>'
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

  context 'when the requested object is an ETD' do
    let(:object) { Etd.new(pid: 'druid:bc123df4567') }

    before do
      object.descMetadata.mods_title = 'Test ETD'
      object.identityMetadata.other_ids = ['dissertationid:00000123']
      object.label = 'foo'
      allow(object).to receive(:collection_ids).and_return([])
    end

    it 'returns the object' do
      get '/v1/objects/druid:bc123df4567',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['externalIdentifier']).to eq 'druid:bc123df4567'
      expect(json['type']).to eq 'http://cocina.sul.stanford.edu/models/object.jsonld'
      expect(json['label']).to eq 'foo'
      expect(json['version']).to eq 1
      expect(json['access']).to eq('access' => 'dark', 'download' => 'none')
      expect(json['identification']).to eq({ 'catalogLinks' => [], 'sourceId' => 'dissertationid:00000123' })
      expect(json['structural']).to eq({ 'contains' => [], 'hasMemberOrders' => [], 'isMemberOf' => [] })
    end
  end
end

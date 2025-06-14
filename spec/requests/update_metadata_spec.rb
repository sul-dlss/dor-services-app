# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update object' do
  let!(:item) { create(:repository_object, :with_repository_object_version, version: 1) }
  let(:druid) { item.external_identifier }
  let(:purl) { "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}" }
  let(:apo) do
    create(:repository_object, :admin_policy, :with_repository_object_version)
  end
  let(:apo_druid) { apo.external_identifier }
  let(:modified) { DateTime.now }
  let(:label) { 'This is my label' }
  let(:title) { 'This is my title' }
  let(:who) { 'test_user' }
  let(:current_collection_druid) { 'druid:xx888xx7777' } # the collection the item is in
  let(:updated_collection_druid) { current_collection_druid } # the collection them item will be updated to

  let(:structural) do
    {
      hasMemberOrders: [
        { viewingDirection: 'right-to-left' }
      ],
      isMemberOf: [current_collection_druid]
    }
  end
  let(:view) { 'world' }
  let(:download) { 'world' }
  let(:cocina_access) do
    Cocina::Models::DROAccess.new(view:, download:)
  end
  let(:expected) do
    build(:dro, id: druid, label:, admin_policy_id: apo_druid, type: Cocina::Models::ObjectType.book).new(
      description:,
      identification:,
      structural:,
      access: {
        copyright: 'All rights reserved unless otherwise indicated.',
        useAndReproductionStatement: 'Property rights reside with the repository...'
      }.merge(cocina_access.to_h)
    )
  end
  let(:description) do
    {
      title: [{ value: title }],
      purl: "https://purl.stanford.edu/#{item.external_identifier.delete_prefix('druid:')}"
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
          "isMemberOf":["#{updated_collection_druid}"]
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
  let(:etag) { item.external_lock }

  let(:headers) do
    {
      'Authorization' => "Bearer #{jwt}",
      'Content-Type' => 'application/json',
      'If-Match' => "W/\"#{etag}\""
    }
  end

  before do
    allow(AdministrativeTags).to receive(:create)
    allow(AdministrativeTags).to receive_messages(project: ['Google Books'], for: [])
    allow(Cocina::ObjectValidator).to receive(:validate)

    allow(EventFactory).to receive(:create)
    allow(VersionService).to receive(:open?).and_return(true)
  end

  context 'when a dro is provided' do
    context 'when valid' do
      before do
        create(:repository_object, :collection, :with_repository_object_version,
               external_identifier: current_collection_druid)
        item.head_version.structural['isMemberOf'] = [current_collection_druid]
        item.head_version.save!
      end

      it 'updates the object' do
        patch("/v1/objects/#{druid}",
              params: data,
              headers:)
        expect(response).to have_http_status(:ok)
        expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data).except('user_name')))
        expect(response.headers['Last-Modified']).to end_with 'GMT'
        expect(response.headers['X-Created-At']).to end_with 'GMT'
        expect(response.headers['ETag']).to match(%r{W/".+"})

        expect(item.reload.head_version.to_cocina.to_json).to equal_cocina_model(expected)
        expect(Cocina::ObjectValidator).to have_received(:validate)

        expect(EventFactory).to have_received(:create).with(druid:, data: hash_including(:request, who:, success: true),
                                                            event_type: 'update')
      end

      context 'when omitted ETag' do
        it 'updates the item' do
          patch "/v1/objects/#{druid}",
                params: data,
                headers: {
                  'Authorization' => "Bearer #{jwt}",
                  'Content-Type' => 'application/json'
                }
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when title changes' do
        let(:description) do
          {
            title: [{ value: 'Not a title' }],
            purl:
          }
        end

        context 'when no description or who are provided' do
          it 'returns the updated object' do
            patch("/v1/objects/#{druid}",
                  params: data,
                  headers:)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include('Not a title')
          end
        end

        context 'when who and description provided' do
          let(:user_name) { 'test_user' }
          let(:event_description) { 'updating stuff' }

          it 'returns the updated object' do
            patch("/v1/objects/#{druid}?event_description=#{event_description}&user_name=#{user_name}",
                  params: data,
                  headers:)
            expect(response).to have_http_status(:ok)
            expect(response.body).to include('Not a title')
          end
        end
      end

      context 'when an image is provided' do
        let(:label) { 'This is my label' }
        let(:expected_label) { label }
        let(:title) { 'This is my title' }
        let(:structural) do
          {
            isMemberOf: [current_collection_druid]
          }
        end
        let(:view) { 'world' }
        let(:expected) do
          build(:dro, id: druid, type: Cocina::Models::ObjectType.image, label: expected_label, title:,
                      admin_policy_id: 'druid:dd999df4567').new(
                        access: {
                          view:,
                          download: 'world',
                          copyright: 'All rights reserved unless otherwise indicated.',
                          useAndReproductionStatement: 'Property rights reside with the repository...'
                        },
                        identification:,
                        structural:
                      )
        end
        let(:data) do
          <<~JSON
            {
              "cocinaVersion": "#{Cocina::Models::VERSION}",
              "externalIdentifier": "#{druid}",
              "type":"#{Cocina::Models::ObjectType.image}",
              "label":"#{expected_label}","version":1,
              "access":{
                "view":"#{view}",
                "download":"world",
                "copyright":"All rights reserved unless otherwise indicated.",
                "useAndReproductionStatement":"Property rights reside with the repository..."
              },
              "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
              "description":{
                "title":[{"value":"#{title}"}],
                "purl":"#{purl}"
              },
              "identification":#{identification.to_json},
              "structural":{
                "isMemberOf":["#{current_collection_druid}"]
              }}
          JSON
        end

        let(:identification) do
          {
            sourceId: 'googlebooks:999999',
            catalogLinks: [
              { catalog: 'symphony', catalogRecordId: '8888', refresh: true }
            ]
          }
        end

        context 'when the save is successful' do
          let(:expected_label) { 'This is a new label' }

          it 'updates the object' do
            patch("/v1/objects/#{druid}",
                  params: data,
                  headers:)
            expect(response).to have_http_status :ok
            expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
            expect(item.reload.head_version.to_cocina.to_json).to equal_cocina_model(expected)

            # Metadata set correctly.
            expect(item.head_version.label).to eq(expected_label)
          end
        end

        # rubocop:disable Layout/LineLength
        context 'when a really long label' do
          let(:label) { 'Hearings before the Subcommittee on Elementary, Secondary, and Vocational Education of the Committee on Education and Labor, House of Representatives, Ninety-fifth Congress, first session, on H.R. 15, to extend for five years certain elementary, secondary, and other education programs ....' }
          let(:truncated_label) { 'Hearings before the Subcommittee on Elementary, Secondary, and Vocational Education of the Committee on Education and Labor, House of Representatives, Ninety-fifth Congress, first session, on H.R. 15, to extend for five years certain elementary, secondar' }

          it 'truncates the title' do
            patch("/v1/objects/#{druid}",
                  params: data,
                  headers:)
            expect(response).to have_http_status(:ok)
            expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
            expect(item.reload.head_version.to_cocina.to_json).to equal_cocina_model(expected)
          end
        end
        # rubocop:enable Layout/LineLength

        context 'when files are provided' do
          let(:file1_id) { 'https://cocina.sul.stanford.edu/file/123-456-789' }
          let(:structural) do
            {
              isMemberOf: [current_collection_druid],
              contains: [
                {
                  type: Cocina::Models::FileSetType.file,
                  externalIdentifier: fileset1_id, label: 'Page 1', version: 1,
                  structural: {
                    contains: [
                      {
                        type: Cocina::Models::ObjectType.file,
                        externalIdentifier: file1_id,
                        label: '00001.html',
                        filename: '00001.html',
                        version: 1,
                        hasMimeType: 'text/html',
                        languageTag: 'aqp-Latn-US',
                        use: 'transcription',
                        hasMessageDigests: [
                          {
                            type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                          }, {
                            type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                          }
                        ],
                        access: { view: 'dark', download: 'none' },
                        administrative: { publish: false, sdrPreserve: true, shelve: false }
                      }, {
                        type: Cocina::Models::ObjectType.file,
                        externalIdentifier: file2_id,
                        label: '00001.jp2',
                        filename: '00001.jp2',
                        version: 1,
                        hasMimeType: 'image/jp2', hasMessageDigests: [],
                        access: { view: 'stanford', download: 'stanford' },
                        administrative: { publish: true, sdrPreserve: true, shelve: true }
                      }
                    ]
                  }
                }, {
                  type: Cocina::Models::FileSetType.file,
                  externalIdentifier: fileset2_id,
                  label: 'Page 2', version: 1,
                  structural: {
                    contains: [
                      {
                        type: Cocina::Models::ObjectType.file,
                        externalIdentifier: file3_id,
                        label: '00002.html', filename: '00002.html',
                        version: 1, hasMimeType: 'text/html',
                        hasMessageDigests: [],
                        access: { view: 'dark', download: 'none' },
                        administrative: { publish: false, sdrPreserve: true, shelve: false }
                      }, {
                        type: Cocina::Models::ObjectType.file,
                        externalIdentifier: file4_id,
                        label: '00002.jp2',
                        filename: '00002.jp2',
                        version: 1,
                        hasMimeType: 'image/jp2',
                        hasMessageDigests: [],
                        access: { view: 'world', download: 'world' },
                        administrative: { publish: true, sdrPreserve: true, shelve: true }
                      }
                    ]
                  }
                }
              ]
            }
          end
          let(:file2_id) { 'https://cocina.sul.stanford.edu/file/223-456-789' }
          let(:file3_id) { 'https://cocina.sul.stanford.edu/file/323-456-789' }
          let(:file4_id) { 'https://cocina.sul.stanford.edu/file/423-456-789' }

          let(:file1) do
            {
              'externalIdentifier' => file1_id,
              'version' => 1,
              'type' => Cocina::Models::ObjectType.file,
              'filename' => '00001.html',
              'label' => '00001.html',
              'hasMimeType' => 'text/html',
              'languageTag' => 'aqp-Latn-US',
              'use' => 'transcription',
              'administrative' => {
                'publish' => false,
                'sdrPreserve' => true,
                'shelve' => false
              },
              'access' => {
                'view' => 'dark'
              },
              'hasMessageDigests' => [
                {
                  'type' => 'sha1',
                  'digest' => 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                },
                {
                  'type' => 'md5',
                  'digest' => 'e6d52da47a5ade91ae31227b978fb023'
                }

              ]
            }
          end

          let(:file2) do
            {
              'externalIdentifier' => file2_id,
              'version' => 1,
              'type' => Cocina::Models::ObjectType.file,
              'filename' => '00001.jp2',
              'label' => '00001.jp2',
              'hasMimeType' => 'image/jp2',
              'administrative' => {
                'publish' => true,
                'sdrPreserve' => true,
                'shelve' => true
              },
              'access' => {
                'view' => 'stanford',
                'download' => 'stanford'
              },
              'hasMessageDigests' => []
            }
          end

          let(:file3) do
            {
              'externalIdentifier' => file3_id,
              'version' => 1,
              'type' => Cocina::Models::ObjectType.file,
              'filename' => '00002.html',
              'label' => '00002.html',
              'hasMimeType' => 'text/html',
              'administrative' => {
                'publish' => false,
                'sdrPreserve' => true,
                'shelve' => false
              },
              'access' => {
                'view' => 'dark',
                'download' => 'none'
              },
              'hasMessageDigests' => []
            }
          end

          let(:file4) do
            {
              'externalIdentifier' => file4_id,
              'version' => 1,
              'type' => Cocina::Models::ObjectType.file,
              'filename' => '00002.jp2',
              'label' => '00002.jp2',
              'hasMimeType' => 'image/jp2',
              'administrative' => {
                'publish' => true,
                'sdrPreserve' => true,
                'shelve' => true
              },
              'access' => {
                'view' => 'world',
                'download' => 'world'
              },
              'hasMessageDigests' => []
            }
          end

          let(:fileset1_id) { 'https://cocina.sul.stanford.edu/fileSet/234-567-890' }
          let(:fileset2_id) { 'https://cocina.sul.stanford.edu/fileSet/334-567-890' }

          let(:filesets) do
            [
              {
                'externalIdentifier' => fileset1_id,
                'version' => 1,
                'type' => Cocina::Models::FileSetType.file,
                'label' => 'Page 1',
                'structural' => { 'contains' => [file1, file2] }
              },
              {
                'externalIdentifier' => fileset2_id,
                'version' => 1,
                'type' => Cocina::Models::FileSetType.file,
                'label' => 'Page 2',
                'structural' => { 'contains' => [file3, file4] }
              }
            ]
          end

          let(:fs1) do
            {
              'type' => Cocina::Models::FileSetType.file
            }
          end
          let(:data) do
            <<~JSON
              {
                "cocinaVersion": "#{Cocina::Models::VERSION}",
                "externalIdentifier": "#{druid}",
                "type":"#{Cocina::Models::ObjectType.image}",
                "label":"#{label}","version":1,
                "access":{
                  "view":"#{view}",
                  "download":"world",
                  "copyright":"All rights reserved unless otherwise indicated.",
                  "useAndReproductionStatement":"Property rights reside with the repository..."
                },
                "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
                "description":{
                  "title":[{"value":"#{title}"}],
                  "purl":"#{purl}"
                },
                "identification":#{identification.to_json},"structural":{"isMemberOf":["#{current_collection_druid}"],"contains":#{filesets.to_json}}}
            JSON
          end

          before do
            # This gives every file and file set the same UUID. In reality, they would be unique.
            allow(SecureRandom).to receive(:uuid).and_return('123-456-789')
          end

          it 'updates the object with files' do
            patch("/v1/objects/#{druid}",
                  params: data,
                  headers:)
            expect(response).to have_http_status(:ok)
            expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
            cocina_item = Cocina::Models.without_metadata(CocinaObjectStore.find(druid))
            expect(cocina_item.to_json).to equal_cocina_model(expected)
            expect(cocina_item.structural.contains.map { |fs| fs.structural.contains.size }).to eq [2, 2]
          end
        end

        context 'when collection is provided' do
          let(:structural) { { isMemberOf: [current_collection_druid] } }

          let(:data) do
            <<~JSON
              {
                "cocinaVersion":"#{Cocina::Models::VERSION}",
                "externalIdentifier": "#{druid}",
                "type":"#{Cocina::Models::ObjectType.image}",
                "label":"#{label}","version":1,
                "access":{
                  "view":"#{view}",
                  "download":"world",
                  "copyright":"All rights reserved unless otherwise indicated.",
                  "useAndReproductionStatement":"Property rights reside with the repository..."
                },
                "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
                "description":{
                  "title":[{"value":"#{title}"}],
                  "purl":"#{purl}"
                },
                "identification":#{identification.to_json},
                "structural":{"isMemberOf":["#{current_collection_druid}"]}}
            JSON
          end

          it 'creates collection relationship' do
            patch("/v1/objects/#{druid}",
                  params: data,
                  headers:)
            expect(response).to have_http_status(:ok)
            expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
            expect(item.reload.head_version.to_cocina.to_json).to equal_cocina_model(expected)
          end
        end
      end

      context 'when a book is provided' do
        let(:label) { 'This is my label' }
        let(:title) { 'This is my title' }
        let(:expected) do
          build(:dro, id: druid, type: Cocina::Models::ObjectType.book, label:, title:,
                      admin_policy_id: 'druid:dd999df4567').new(
                        identification: { sourceId: 'googlebooks:999999' },
                        structural: {
                          hasMemberOrders: [
                            { viewingDirection: 'right-to-left' }
                          ],
                          isMemberOf: [current_collection_druid]
                        },
                        access: { view: 'world', download: 'world' }
                      )
        end
        let(:data) do
          <<~JSON
            {
              "cocinaVersion": "#{Cocina::Models::VERSION}",
              "externalIdentifier": "#{druid}",
              "type":"#{Cocina::Models::ObjectType.book}",
              "label":"#{label}","version":1,
              "access":{
                "view":"world",
                "download":"world"
              },
              "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
              "description":{
                "title":[{"value":"#{title}"}],
                "purl":"#{purl}"
              },
              "identification":{"sourceId":"googlebooks:999999"},
              "structural":{
                "hasMemberOrders":[{"viewingDirection":"right-to-left"}],
                "isMemberOf":["#{current_collection_druid}"]
              }}
          JSON
        end

        before do
          allow(AdministrativeTags).to receive(:project).and_return([])
        end

        it 'registers the book and sets the viewing direction' do
          patch("/v1/objects/#{druid}",
                params: data,
                headers:)

          expect(response).to have_http_status(:ok)
          expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
          expect(item.reload.head_version.to_cocina.to_json).to equal_cocina_model(expected)
        end
      end

      context 'when an embargo is provided' do
        let(:expected) do
          build(:dro, id: druid, label: 'This is my label', title: 'This is my title', admin_policy_id: apo_druid,
                      type: Cocina::Models::ObjectType.book).new(
                        identification: { sourceId: 'googlebooks:999999' },
                        structural: {
                          isMemberOf: [current_collection_druid],
                          hasMemberOrders: [
                            { viewingDirection: 'right-to-left' }
                          ]
                        },
                        access: {
                          view: 'stanford',
                          download: 'stanford',
                          embargo: {
                            view: 'world',
                            download: 'world',
                            releaseDate: '2020-02-29T07:00:00.000+00:00'
                          }
                        }
                      )
        end
        let(:data) do
          <<~JSON
            {
              "cocinaVersion": "#{Cocina::Models::VERSION}",
              "externalIdentifier": "#{druid}",
              "type":"#{Cocina::Models::ObjectType.book}",
              "label":"This is my label","version":1,
              "access":{"view":"stanford","download":"stanford",
                "embargo":{"view":"world","download":"world","releaseDate":"2020-02-29T07:00:00.000+00:00"}
              },
              "administrative":{"hasAdminPolicy":"#{apo_druid}"},
              "description":{
                "title":[{"value":"This is my title"}],
                "purl":"#{purl}"
              },
              "identification":{"sourceId":"googlebooks:999999"},
              "structural":{"isMemberOf":["#{current_collection_druid}"],"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
          JSON
        end
        let(:view) { 'stanford' }
        let(:download) { 'stanford' }

        before do
          allow(AdministrativeTags).to receive(:project).and_return([])
        end

        it 'registers the book and sets the rights' do
          patch("/v1/objects/#{druid}",
                params: data,
                headers:)
          expect(response).to have_http_status(:ok)
          expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
          expect(item.reload.head_version.to_cocina.to_json).to equal_cocina_model(expected)
        end
      end

      context 'when a dro is moved from one collection to another' do
        let(:new_collection_druid) { 'druid:bb111bb2222' }
        # this simulates moving from one collection to another
        let(:updated_collection_druid) { new_collection_druid }

        before do
          create(:repository_object_version, :with_repository_object, :collection_repository_object_version,
                 title: 'New Collection', external_identifier: new_collection_druid)
        end

        it 'sends a collection changed event' do
          patch("/v1/objects/#{druid}",
                params: data,
                headers:)
          expect(response).to have_http_status(:ok)
          description = "Moved from Test Collection (#{current_collection_druid}) " \
                        "to New Collection (#{new_collection_druid})"
          expect(EventFactory).to have_received(:create).with(druid:, event_type: 'collection_changed',
                                                              data: { who:, description: })
        end
      end

      context 'when a dro is removed from a collection' do
        let(:data) do
          <<~JSON
            {
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
                "hasMemberOrders":[{"viewingDirection":"right-to-left"}]
              }
            }
          JSON
        end

        it 'sends a collection changed event' do
          patch("/v1/objects/#{druid}",
                params: data,
                headers:)
          expect(response).to have_http_status(:ok)
          description = "Moved from Test Collection (#{current_collection_druid}) to None ()"
          expect(EventFactory).to have_received(:create).with(druid:, event_type: 'collection_changed',
                                                              data: { who: nil, description: })
        end
      end

      context 'when a dro is added to a collection' do
        before do
          item.head_version.structural['isMemberOf'] = []
          item.head_version.save!
        end

        it 'sends a collection changed event' do
          patch("/v1/objects/#{druid}",
                params: data,
                headers:)
          expect(response).to have_http_status(:ok)
          description = "Moved from None () to Test Collection (#{current_collection_druid})"
          expect(EventFactory).to have_received(:create).with(druid:, event_type: 'collection_changed',
                                                              data: { who:, description: })
        end
      end
    end

    context 'when invalid' do
      context 'when access mismatch' do
        let(:view) { 'dark' }
        let(:download) { 'none' }

        it 'returns 400' do
          patch("/v1/objects/#{druid}",
                params: data,
                headers:)
          expect(response).to have_http_status :bad_request
        end
      end

      context 'with a non-matching druid (Cocina::Models::ValidationError)' do
        let(:data) do
          <<~JSON
            {
              "cocinaVersion": "#{Cocina::Models::VERSION}",
              "externalIdentifier": "druid:xs123xx8388",
              "type":"#{content_type}",
              "label":"#{label}","version":1,
              "access":{
                "view":"#{view}",
                "download":"#{view}",
                "copyright":"All rights reserved unless otherwise indicated.",
                "useAndReproductionStatement":"Property rights reside with the repository..."
              },
              "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
              "description":#{description.to_json},
              "identification":#{identification.to_json},
              "structural":{
                "hasMemberOrders":[{"viewingDirection":"right-to-left"}],
              }
            }
          JSON
        end
        let(:description) do
          {
            title: [{ value: title }],
            purl: 'https://purl.stanford.edu/xs123xx8388'
          }
        end

        it 'is a bad request' do
          patch("/v1/objects/#{druid}",
                params: data,
                headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'when validation fails' do
        before do
          allow(Cocina::ObjectValidator).to receive(:validate).and_raise(Cocina::ValidationError, 'Not on my watch.')
        end

        it 'is a bad request' do
          patch("/v1/objects/#{druid}",
                params: data,
                headers:)
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'when incorrect ETag' do
        it 'is a stale request and does not save' do
          patch "/v1/objects/#{druid}",
                params: data,
                headers: {
                  'Authorization' => "Bearer #{jwt}",
                  'Content-Type' => 'application/json',
                  'If-Match' => 'W/"BAD LOCK"'
                }
          expect(response).to have_http_status(:precondition_failed)
        end
      end
    end
  end

  context 'when a collection is provided' do
    let!(:item) { create(:repository_object, :collection, :with_repository_object_version, version: 1) }
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected) do
      build(:collection, id: druid, label:, title:, admin_policy_id: 'druid:dd999df4567').new(
        identification:
      )
    end
    let(:identification) do
      {
        catalogLinks: [
          { catalog: 'symphony', catalogRecordId: '8888', refresh: true }
        ]
      }
    end

    let(:data) do
      <<~JSON
        {
          "cocinaVersion": "#{Cocina::Models::VERSION}",
          "externalIdentifier": "#{druid}",
          "type":"#{Cocina::Models::ObjectType.collection}",
          "label":"#{label}","version":1,
          "access":{},
          "identification":#{identification.to_json},
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
          "description":{
            "title":[{"value":"#{title}"}],
            "purl":"#{purl}"
          }
        }
      JSON
    end

    before do
      allow(AdministrativeTags).to receive(:project).and_return([])
    end

    it 'updates the collection' do
      patch("/v1/objects/#{druid}",
            params: data,
            headers:)
      expect(response).to have_http_status(:ok)
      expect(PublishItemsModifiedJob).to have_been_enqueued
      expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
      expect(item.reload.head_version.to_cocina.to_json).to equal_cocina_model(expected)
    end
  end

  context 'when an APO is provided' do
    let(:druid) { 'druid:yq561fh2083' }
    let!(:item) do
      repository_object_version = build(:repository_object_version, :admin_policy_repository_object_version,
                                        external_identifier: druid, access_template: default_access, version: 1)
      create(:repository_object, :collection, :with_repository_object_version, repository_object_version:,
                                                                               external_identifier: druid)
    end

    let(:expected) do
      build(:admin_policy, id: druid, label: 'This is my label', title: 'This is my title').new(
        administrative: {
          accessTemplate: default_access_expected,
          hasAdminPolicy: 'druid:dd999df4567',
          hasAgreement: 'druid:bc123df4567',
          disseminationWorkflow: 'assemblyWF',
          registrationWorkflow: %w[goobiWF registrationWF],
          collectionsForRegistration: ['druid:gg888df4567', 'druid:bb888gg4444'],
          roles: [
            {
              name: 'dor-apo-manager',
              members: [
                {
                  type: 'workgroup',
                  identifier: 'sdr:psm-staff'
                }
              ]
            }
          ]
        }
      )
    end

    let(:default_access) do
      {
        view: 'location-based',
        download: 'location-based',
        location: 'ars',
        copyright: 'My copyright statement',
        license: 'https://opendatacommons.org/licenses/by/1-0/',
        useAndReproductionStatement: 'Whatever makes you happy'
      }
    end
    let(:default_access_expected) { default_access }

    let(:data) do
      <<~JSON
        {
          "cocinaVersion": "#{Cocina::Models::VERSION}",
          "externalIdentifier": "#{druid}",
          "type":"#{Cocina::Models::ObjectType.admin_policy}",
          "label":"This is my label",
          "version":1,
          "administrative":{
            "disseminationWorkflow":"assemblyWF",
            "registrationWorkflow":["goobiWF","registrationWF"],
            "collectionsForRegistration":["druid:gg888df4567","druid:bb888gg4444"],
            "hasAdminPolicy":"druid:dd999df4567",
            "hasAgreement":"druid:bc123df4567",
            "accessTemplate":#{default_access.to_json},
            "roles":[{"name":"dor-apo-manager","members":[{"type":"workgroup","identifier":"sdr:psm-staff"}]}]
          },
          "description":{
            "title":[{"value":"This is my title"}],
            "purl":"#{purl}"
          }
        }
      JSON
    end

    context 'when the request is successful' do
      it 'registers the object with the registration service' do
        patch("/v1/objects/#{druid}",
              params: data,
              headers:)
        expect(response).to have_http_status(:ok)
        expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
        expect(item.reload.head_version.to_cocina.to_json).to equal_cocina_model(expected)
      end
    end

    context 'when the request clears out some values' do
      let(:default_access) do
        {
          view: 'world',
          download: 'world',
          location: nil,
          copyright: nil,
          license: nil,
          useAndReproductionStatement: nil
        }
      end

      it 'updates the metadata' do
        patch("/v1/objects/#{druid}",
              params: data,
              headers:)
        expect(response).to have_http_status(:ok)
        expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
        expect(item.reload.head_version.to_cocina.to_json).to equal_cocina_model(expected)
      end
    end
  end
end

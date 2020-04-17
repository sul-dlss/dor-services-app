# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update object' do
  before do
    allow(Dor).to receive(:find).with(druid).and_return(item)
    allow(Dor).to receive(:find).with(apo_druid).and_return(apo)
    allow(item).to receive(:save!)
    allow(item).to receive(:new_record?).and_return(false)

    # Stub out AF for ObjectUpdater
    allow(item.association(:collections)).to receive(:ids_writer).and_return(true)
    # Stub out AF for ObjectMapper
    allow(item).to receive(:collection_ids).and_return ['druid:xx888xx7777']
  end

  let(:apo) { Dor::AdminPolicyObject.new(pid: apo_druid) }
  let(:item) { Dor::Item.new(pid: druid) }

  let(:druid) { 'druid:gg777gg7777' }
  let(:apo_druid) { 'druid:dd999df4567' }

  let(:label) { 'This is my label' }
  let(:title) { 'This is my title' }
  let(:expected_label) { label }
  let(:structural) do
    {
      hasMemberOrders: [
        { viewingDirection: 'right-to-left' }
      ],
      isMemberOf: 'druid:xx888xx7777'
    }
  end
  let(:access) { 'world' }
  let(:expected) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::Vocab.book,
                            label: expected_label,
                            version: 1,
                            access: {
                              access: access,
                              copyright: 'All rights reserved unless otherwise indicated.',
                              useAndReproductionStatement: 'Property rights reside with the repository...'
                            },
                            description: {
                              title: [{ value: title, status: 'primary' }]
                            },
                            administrative: {
                              hasAdminPolicy: apo_druid,
                              partOfProject: 'Google Books'
                            },
                            identification: identification,
                            structural: structural)
  end
  let(:data) do
    <<~JSON
      {
        "externalIdentifier": "#{druid}",
        "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
        "label":"#{label}","version":1,
        "access":{
          "access":"#{access}",
          "copyright":"All rights reserved unless otherwise indicated.",
          "useAndReproductionStatement":"Property rights reside with the repository..."
        },
        "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
        "description":{"title":[{"status":"primary","value":"#{title}"}]},
        "identification":#{identification.to_json},
        "structural":{
          "hasMemberOrders":[{"viewingDirection":"right-to-left"}],
          "isMemberOf":"druid:xx888xx7777"
        }
      }
    JSON
  end

  let(:identification) do
    { sourceId: 'googlebooks:999999' }
  end

  it 'updates the object' do
    patch "/v1/objects/#{druid}",
          params: data,
          headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

    expect(response.status).to eq(200)
    expect(item).to have_received(:save!)
    expect(response.body).to eq expected.to_json
  end

  context 'when an image is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:structural) do
      {
        isMemberOf: 'druid:xx888xx7777'
      }
    end
    let(:access) { 'world' }
    let(:expected) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::Vocab.image,
                              label: expected_label,
                              version: 1,
                              access: {
                                access: access,
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: {
                                title: [{ value: title, status: 'primary' }]
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567',
                                partOfProject: 'Google Books'
                              },
                              identification: identification,
                              structural: structural)
    end
    let(:data) do
      <<~JSON
        {
          "externalIdentifier": "#{druid}",
          "type":"http://cocina.sul.stanford.edu/models/image.jsonld",
          "label":"#{label}","version":1,
          "access":{
            "access":"#{access}",
            "copyright":"All rights reserved unless otherwise indicated.",
            "useAndReproductionStatement":"Property rights reside with the repository..."
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
          "description":{"title":[{"status":"primary","value":"#{title}"}]},
          "identification":#{identification.to_json},
          "structural":{
            "isMemberOf":"druid:xx888xx7777"
          }}
      JSON
    end

    let(:identification) do
      {
        sourceId: 'googlebooks:999999',
        catalogLinks: [
          { catalog: 'symphony', catalogRecordId: '8888' }
        ]
      }
    end

    context 'when the save is successful' do
      it 'updates the object' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq 200

        # Identity metadata set correctly.
        expect(item.objectId).to eq(druid)
        expect(item.objectCreator.first).to eq('DOR')
        expect(item.objectLabel.first).to eq(expected_label)
        expect(item.objectType.first).to eq('item')
      end
    end

    # rubocop:disable Metrics/LineLength
    context 'when a really long label' do
      let(:label) { 'Hearings before the Subcommittee on Elementary, Secondary, and Vocational Education of the Committee on Education and Labor, House of Representatives, Ninety-fifth Congress, first session, on H.R. 15, to extend for five years certain elementary, secondary, and other education programs ....' }
      let(:truncated_label) { 'Hearings before the Subcommittee on Elementary, Secondary, and Vocational Education of the Committee on Education and Labor, House of Representatives, Ninety-fifth Congress, first session, on H.R. 15, to extend for five years certain elementary, secondar' }

      it 'truncates the title' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(200)

        # Identity metadata set correctly.
        expect(item.objectLabel.first).to eq(expected_label)
        expect(item.objectType.first).to eq('item')
      end
    end
    # rubocop:enable Metrics/LineLength

    context 'when files are provided' do
      let(:file1) do
        {
          'externalIdentifier' => 'file1',
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00001.html',
          'label' => '00001.html',
          'hasMimeType' => 'text/html',
          'use' => 'transcription',
          'administrative' => {
            'sdrPreserve' => true,
            'shelve' => false
          },
          'access' => {
            'access' => 'dark'
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
          'externalIdentifier' => 'file2',
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00001.jp2',
          'label' => '00001.jp2',
          'hasMimeType' => 'image/jp2',
          'administrative' => {
            'sdrPreserve' => true,
            'shelve' => true
          },
          'access' => {
            'access' => 'stanford'
          },
          'hasMessageDigests' => []
        }
      end

      let(:file3) do
        {
          'externalIdentifier' => 'file3',
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00002.html',
          'label' => '00002.html',
          'hasMimeType' => 'text/html',
          'administrative' => {
            'sdrPreserve' => true,
            'shelve' => false
          },
          'access' => {
            'access' => 'world'
          },
          'hasMessageDigests' => []
        }
      end

      let(:file4) do
        {
          'externalIdentifier' => 'file4',
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00002.jp2',
          'label' => '00002.jp2',
          'hasMimeType' => 'image/jp2',
          'administrative' => {
            'sdrPreserve' => true,
            'shelve' => true
          },
          'access' => {
            'access' => 'world'
          },
          'hasMessageDigests' => []
        }
      end

      let(:filesets) do
        [
          {
            'externalIdentifier' => 'fs1',
            'version' => 1,
            'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            'label' => 'Page 1',
            'structural' => { 'contains' => [file1, file2] }
          },
          {
            'externalIdentifier' => 'fs2',
            'version' => 1,
            'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            'label' => 'Page 2',
            'structural' => { 'contains' => [file3, file4] }
          }
        ]
      end

      let(:fs1) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld'
        }
      end
      let(:data) do
        <<~JSON
          {
            "externalIdentifier": "#{druid}",
            "type":"http://cocina.sul.stanford.edu/models/image.jsonld",
            "label":"#{label}","version":1,
            "access":{
              "access":"#{access}",
              "copyright":"All rights reserved unless otherwise indicated.",
              "useAndReproductionStatement":"Property rights reside with the repository..."
            },
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
            "description":{"title":[{"status":"primary","value":"#{title}"}]},
            "identification":#{identification.to_json},"structural":{"contains":#{filesets.to_json}}}
        JSON
      end

      context 'when access match' do
        it 'creates contentMetadata' do
          patch "/v1/objects/#{druid}",
                params: data,
                headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

          expect(response.body).to eq expected.to_json
          expect(response.status).to eq(200)
          expect(item.contentMetadata.resource.file.count).to eq 4
        end
      end

      context 'when access mismatch' do
        let(:access) { 'dark' }

        it 'returns 400' do
          patch "/v1/objects/#{druid}",
                params: data,
                headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.status).to eq(400)
          expect(response.body).to eq('Not all files have dark access and/or are unshelved when item access is dark: ["00001.jp2", "00002.html", "00002.jp2"]')
        end
      end
    end

    context 'when collection is provided' do
      let(:structural) { { isMemberOf: 'druid:xx888xx7777' } }

      let(:data) do
        <<~JSON
          {
            "externalIdentifier": "#{druid}",
            "type":"http://cocina.sul.stanford.edu/models/image.jsonld",
            "label":"#{label}","version":1,
            "access":{
              "access":"#{access}",
              "copyright":"All rights reserved unless otherwise indicated.",
              "useAndReproductionStatement":"Property rights reside with the repository..."
            },
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
            "description":{"title":[{"status":"primary","value":"#{title}"}]},
            "identification":#{identification.to_json},
            "structural":{"isMemberOf":"druid:xx888xx7777"}}
        JSON
      end

      it 'creates collection relationship' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(200)
      end
    end
  end

  context 'when a book is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.book,
                              label: expected_label,
                              version: 1,
                              description: {
                                title: [{ value: title, status: 'primary' }]
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567'
                              },
                              identification: { sourceId: 'googlebooks:999999' },
                              externalIdentifier: druid,
                              structural: {
                                hasMemberOrders: [
                                  { viewingDirection: 'right-to-left' }
                                ],
                                isMemberOf: 'druid:xx888xx7777'
                              },
                              access: { access: 'world' })
    end
    let(:data) do
      <<~JSON
        {
          "externalIdentifier": "#{druid}",
          "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"#{label}","version":1,
          "access":{
            "access":"world"
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"status":"primary","value":"#{title}"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{
            "hasMemberOrders":[{"viewingDirection":"right-to-left"}],
            "isMemberOf":"druid:xx888xx7777"
          }}
      JSON
    end

    it 'registers the book and sets the viewing direction' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response.body).to eq expected.to_json
      expect(response.status).to eq(200)
    end
  end

  context 'when a collection is provided' do
    let(:item) { Dor::Collection.new(pid: druid) }

    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected_label) { label }
    let(:expected) do
      Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                     label: expected_label,
                                     version: 1,
                                     description: {
                                       title: [{ value: title, status: 'primary' }]
                                     },
                                     administrative: {
                                       hasAdminPolicy: 'druid:dd999df4567'
                                     },
                                     externalIdentifier: druid,
                                     access: {})
    end
    let(:data) do
      <<~JSON
        {
          "externalIdentifier": "#{druid}",
          "type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
          "label":"#{label}","version":1,
          "access":{},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"status":"primary","value":"#{title}"}]}}
      JSON
    end

    it 'creates the collection' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to eq expected.to_json
      expect(response.status).to eq(200)
    end
  end

  context 'when an APO is provided' do
    let(:item) { Dor::AdminPolicyObject.new(pid: druid) }

    let(:expected) do
      Cocina::Models::AdminPolicy.new(type: Cocina::Models::Vocab.admin_policy,
                                      label: 'This is my label',
                                      version: 1,
                                      description: {
                                        title: [{ value: 'This is my title', status: 'primary' }]
                                      },
                                      administrative: {
                                        defaultObjectRights: default_object_rights,
                                        hasAdminPolicy: 'druid:dd999df4567',
                                        registrationWorkflow: 'assemblyWF'
                                      },
                                      externalIdentifier: druid)
    end

    let(:default_object_rights) { Dor::DefaultObjectRightsDS.new.content }

    let(:data) do
      <<~JSON
        {
          "externalIdentifier": "#{druid}",
          "type":"http://cocina.sul.stanford.edu/models/admin_policy.jsonld",
          "label":"This is my label","version":1,
          "administrative":{
            "defaultObjectRights":#{default_object_rights.to_json},
            "registrationWorkflow":"assemblyWF",
            "hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"status":"primary","value":"This is my title"}]}}
      JSON
    end

    context 'when the request is successful' do
      before do
        # This stubs out Solr:
        allow(item).to receive(:admin_policy_object_id).and_return('druid:dd999df4567')
      end

      it 'registers the object with the registration service' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json

        expect(response.status).to eq(200)
      end
    end
  end

  context 'when an embargo is provided' do
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.book,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ value: 'This is my title', status: 'primary' }]
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567'
                              },
                              identification: { sourceId: 'googlebooks:999999' },
                              externalIdentifier: 'druid:gg777gg7777',
                              structural: {
                                hasMemberOrders: [
                                  { viewingDirection: 'right-to-left' }
                                ],
                                isMemberOf: 'druid:xx888xx7777'
                              },
                              access: { access: 'citation-only', embargo: { access: 'world', releaseDate: '2020-02-29' } })
    end
    let(:data) do
      <<~JSON
        {
          "externalIdentifier": "#{druid}",
          "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"This is my label","version":1,
          "access":{"access":"world",
            "embargo":{"access":"world","releaseDate":"2020-02-29"}
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"status":"primary","value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end

    it 'registers the book and sets the rights' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response.body).to eq expected.to_json
      expect(response.status).to eq(200)
    end
  end
end

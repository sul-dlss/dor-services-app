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
    allow(item).to receive(:collections).and_return [collection]
    allow(item).to receive(:admin_policy_object_id=)
    allow(AdministrativeTags).to receive(:create)
    allow(AdministrativeTags).to receive(:project).and_return(['Google Books'])
    allow(AdministrativeTags).to receive(:content_type).and_return(['Book (rtl)'])
    allow(AdministrativeTags).to receive(:for).and_return([])

    allow(EventFactory).to receive(:create)
  end

  let(:collection) { Dor::Collection.new(pid: 'druid:xx888xx7777') }
  let(:apo) { Dor::AdminPolicyObject.new(pid: apo_druid) }
  let(:item) do
    Dor::Item.new(pid: druid,
                  source_id: 'googlebooks:111111',
                  label: label,
                  admin_policy_object_id: apo_druid).tap do |item|
      item.descMetadata.title_info.main_title = title
      item.contentMetadata.contentType = ['book']
      item.identityMetadata.barcode = '36105036289000'
    end
  end

  let(:druid) { 'druid:gg777gg7777' }
  let(:apo_druid) { 'druid:dd999df4567' }

  let(:label) { 'This is my label' }
  let(:title) { 'This is my title' }
  let(:structural) do
    {
      hasMemberOrders: [
        { viewingDirection: 'right-to-left' }
      ],
      isMemberOf: ['druid:xx888xx7777'],
      hasAgreement: 'druid:cd777df7777'
    }
  end
  let(:access) { 'world' }
  let(:expected) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::Vocab.book,
                            label: label,
                            version: 1,
                            access: {
                              access: access,
                              download: 'world',
                              copyright: 'All rights reserved unless otherwise indicated.',
                              useAndReproductionStatement: 'Property rights reside with the repository...'
                            },
                            description: {
                              title: [{ value: title }],
                              purl: 'http://purl.stanford.edu/gg777gg7777',
                              access: {
                                digitalRepository: [
                                  { value: 'Stanford Digital Repository' }
                                ]
                              }
                            },
                            administrative: {
                              hasAdminPolicy: apo_druid,
                              partOfProject: 'Google Books'
                            },
                            identification: identification,
                            structural: structural)
  end

  let(:description) do
    { title: [{ value: title }] }
  end

  let(:data) do
    <<~JSON
      {
        "externalIdentifier": "#{druid}",
        "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
        "label":"#{label}","version":1,
        "access":{
          "access":"#{access}",
          "download":"world",
          "copyright":"All rights reserved unless otherwise indicated.",
          "useAndReproductionStatement":"Property rights reside with the repository..."
        },
        "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
        "description":#{description.to_json},
        "identification":#{identification.to_json},
        "structural":{
          "hasMemberOrders":[{"viewingDirection":"right-to-left"}],
          "isMemberOf":["druid:xx888xx7777"],
          "hasAgreement":"druid:cd777df7777"
        }
      }
    JSON
  end

  let(:identification) do
    {
      sourceId: 'googlebooks:999999',
      barcode: '36105036289127'
    }
  end

  it 'updates the object' do
    patch "/v1/objects/#{druid}",
          params: data,
          headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
    expect(response.status).to eq(200)
    expect(item).to have_received(:save!)
    expect(item).to have_received(:admin_policy_object_id=).with(apo_druid)
    expect(response.body).to equal_cocina_model(expected)

    # Tags are created.
    expect(AdministrativeTags).to have_received(:create).with(pid: druid, tags: ['Process : Content Type : Book (rtl)'])
    expect(AdministrativeTags).to have_received(:create).with(pid: druid, tags: ['Project : Google Books'])
    expect(EventFactory).to have_received(:create).with(druid: druid, data: hash_including(:request, success: true), event_type: 'update')
  end

  context 'when update_descriptive is true' do
    let(:description) do
      {
        title: [{ value: title }],
        subject: [
          { type: 'topic', value: 'MyString' }
        ],
        note: [
          { type: 'summary', value: 'test abstract' },
          { type: 'preferred citation', value: 'test citation' },
          { displayLabel: 'Contact', type: 'email', value: 'io@io.io' }
        ],
        purl: 'http://purl.stanford.edu/gg777gg7777',
        access: {
          digitalRepository: [
            { value: 'Stanford Digital Repository' }
          ]
        }
      }
    end

    let(:expected) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::Vocab.book,
                              label: label,
                              version: 1,
                              access: {
                                access: access,
                                download: 'world',
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: description,
                              administrative: {
                                hasAdminPolicy: apo_druid,
                                partOfProject: 'Google Books'
                              },
                              identification: identification,
                              structural: structural)
    end

    before do
      allow(Settings.enabled_features).to receive(:update_descriptive).and_return(true)
    end

    context 'when roundtrip validation is successful' do
      it 'updates the descriptive metadata' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(200)
        expect(item).to have_received(:save!)
        expect(response.body).to equal_cocina_model(expected)
      end
    end

    context 'when roundtrip validation is unsuccessful' do
      let(:changed_description) do
        description.dup.tap { |descr| descr[:title] = [{ value: 'different title' }] }
      end

      before do
        allow(Honeybadger).to receive(:notify)
        allow(Cocina::FromFedora::Descriptive).to receive(:props).and_return(changed_description)
      end

      it 'returns error' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(409)
        expect(item).not_to have_received(:save!)
        expect(Honeybadger).to have_received(:notify)
      end
    end
  end

  context 'with a structured title that has nonsorting characters' do
    # This tests the problem found in https://github.com/sul-dlss/argo/issues/2253
    # where an integer value in a string field was being detected as invalid data.
    let(:description) do
      {
        title: [
          {
            structuredValue: [
              { value: 'The', type: 'nonsorting characters' },
              { value: 'romantic Bach', type: 'main title' },
              { value: "a celebration of Bach's most romantic music", type: 'subtitle' }
            ],
            note: [
              { value: '4', type: 'nonsorting character count' }
            ]
          }
        ]
      }
    end

    let(:ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <nonSort xml:space="preserve">The</nonSort>
            <title>romantic Bach</title>
            <subTitle>a celebration of Bach's most romantic music</subTitle>
          </titleInfo>
        </mods>
      XML
    end

    let(:item) do
      Dor::Item.new(pid: druid,
                    source_id: 'google_books:99999',
                    label: label,
                    admin_policy_object_id: apo_druid).tap do |item|
        item.descMetadata.content = ng_xml.to_xml
      end
    end

    it 'accepts the request with a supplied nonsorting character count' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(item).to have_received(:save!)
    end
  end

  context 'with a structured title' do
    let(:expected) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::Vocab.book,
                              label: label,
                              version: 1,
                              access: {
                                access: access,
                                download: 'world',
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: {
                                title: [
                                  {
                                    structuredValue: [
                                      {
                                        value: title,
                                        type: 'main title'
                                      },
                                      {
                                        value: '(repeat)',
                                        type: 'subtitle'
                                      }
                                    ]
                                  }
                                ],
                                purl: 'http://purl.stanford.edu/gg777gg7777',
                                access: {
                                  digitalRepository: [
                                    { value: 'Stanford Digital Repository' }
                                  ]
                                }
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
            "download":"world",
            "copyright":"All rights reserved unless otherwise indicated.",
            "useAndReproductionStatement":"Property rights reside with the repository..."
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
          "description":{"title":[{"structuredValue":[{"value":"#{title}","type":"main title"},{"value":"(repeat)","type":"subtitle"}]}]},
          "identification":#{identification.to_json},
          "structural":{
            "hasMemberOrders":[{"viewingDirection":"right-to-left"}],
            "isMemberOf":["druid:xx888xx7777"],
            "hasAgreement":"druid:cd777df7777"
          }
        }
      JSON
    end
    let(:item) do
      Dor::Item.new(pid: druid,
                    source_id: 'google_books:99999',
                    label: label,
                    admin_policy_object_id: apo_druid).tap do |item|
        # Dor::DescMetadataDS does not have a setter for subtitles
        item.descMetadata.content = <<~XML
          <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title>#{title}</title>
              <subTitle>(repeat)</subTitle>
            </titleInfo>
          </mods>
        XML
        item.contentMetadata.contentType = ['book']
      end
    end

    it 'updates the object' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(item).to have_received(:save!)
      expect(response.body).to equal_cocina_model(expected)
    end
  end

  context 'when the object is a hydrus item' do
    # This is how the item looks in the repository before being updated
    let(:item) do
      Dor::Item.new(pid: druid,
                    source_id: 'google_books:99999',
                    admin_policy_object_id: apo_druid,
                    label: 'Hydrus').tap do |item|
        # Hydrus doesn't fill in a title right away.
        item.descMetadata.content = <<~XML
          <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
            <titleInfo>
              <title/>
            </titleInfo>
          </mods>
        XML

        item.contentMetadata.contentType = ['book']
      end
    end

    let(:title) { 'Hydrus' } # The title in the request (data)
    let(:label) { 'Hydrus' } # This is the label in the request (data)

    it 'updates the object' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(item).to have_received(:save!)
      expect(response.body).to equal_cocina_model(expected)
    end
  end

  context 'when tags change' do
    before do
      allow(AdministrativeTags).to receive(:for).and_return(['Project : Tom Swift', 'Process : Content Type : Book (ltr)'])
      allow(AdministrativeTags).to receive(:update)
    end

    it 'updates the object and the tags' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(item).to have_received(:save!)
      expect(response.body).to equal_cocina_model(expected)

      # Tags are updated.
      expect(AdministrativeTags).not_to have_received(:create)
      expect(AdministrativeTags).to have_received(:update).with(pid: druid, current: 'Process : Content Type : Book (ltr)', new: 'Process : Content Type : Book (rtl)')
      expect(AdministrativeTags).to have_received(:update).with(pid: druid, current: 'Project : Tom Swift', new: 'Project : Google Books')
    end
  end

  context 'when tags do not change' do
    before do
      allow(AdministrativeTags).to receive(:for).and_return(['Project : Google Books', 'Process : Content Type : Book (rtl)'])
    end

    it 'updates the object but not the tags' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(item).to have_received(:save!)
      expect(response.body).to equal_cocina_model(expected)

      # Tags are not updated or created.
      expect(AdministrativeTags).not_to have_received(:create)
    end
  end

  context 'with bad data' do
    before do
      allow(Dor).to receive(:find).with(other_druid).and_return(item)
    end

    let(:item) do
      Dor::Item.new(pid: other_druid,
                    source_id: 'google_books:99999',
                    label: label,
                    admin_policy_object_id: apo_druid).tap do |item|
        item.descMetadata.title_info.main_title = title
      end
    end

    let(:other_druid) { 'druid:xs123xx8388' }

    it 'is a bad request' do
      patch "/v1/objects/#{other_druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(400)
      expect(EventFactory).to have_received(:create)
        .with(druid: other_druid,
              data: hash_including(:request, success: false, error: "Identifier on the query and in the body don't match"),
              event_type: 'update')
    end
  end

  context 'when title changes' do
    before do
      item.descMetadata.title_info.main_title = 'Not the title'
    end

    it 'raises 422' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(422)
    end
  end

  context 'when an image is provided' do
    let(:label) { 'This is my label' }
    let(:expected_label) { label }
    let(:title) { 'This is my title' }
    let(:structural) do
      {
        isMemberOf: ['druid:xx888xx7777']
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
                                download: 'world',
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: {
                                title: [{ value: title }],
                                purl: 'http://purl.stanford.edu/gg777gg7777',
                                access: {
                                  digitalRepository: [
                                    { value: 'Stanford Digital Repository' }
                                  ]
                                }
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
          "label":"#{expected_label}","version":1,
          "access":{
            "access":"#{access}",
            "download":"world",
            "copyright":"All rights reserved unless otherwise indicated.",
            "useAndReproductionStatement":"Property rights reside with the repository..."
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
          "description":{"title":[{"value":"#{title}"}]},
          "identification":#{identification.to_json},
          "structural":{
            "isMemberOf":["druid:xx888xx7777"]
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

    before do
      allow(AdministrativeTags).to receive(:content_type).and_return(['Image'])
    end

    context 'when the save is successful' do
      let(:expected_label) { 'This is a new label' }

      it 'updates the object' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(response.status).to eq 200

        # Identity metadata set correctly.
        expect(item.objectId).to eq(druid)
        expect(item.objectCreator.first).to eq('DOR')
        expect(item.objectLabel.first).to eq(expected_label)
        expect(item.objectType.first).to eq('item')
      end
    end

    # rubocop:disable Layout/LineLength
    context 'when a really long label' do
      let(:label) { 'Hearings before the Subcommittee on Elementary, Secondary, and Vocational Education of the Committee on Education and Labor, House of Representatives, Ninety-fifth Congress, first session, on H.R. 15, to extend for five years certain elementary, secondary, and other education programs ....' }
      let(:truncated_label) { 'Hearings before the Subcommittee on Elementary, Secondary, and Vocational Education of the Committee on Education and Labor, House of Representatives, Ninety-fifth Congress, first session, on H.R. 15, to extend for five years certain elementary, secondar' }

      it 'truncates the title' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(response.status).to eq(200)
      end
    end
    # rubocop:enable Layout/LineLength

    context 'when files are provided' do
      let(:file1) do
        {
          'externalIdentifier' => 'http://cocina.sul.stanford.edu/file/123-456-789',
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00001.html',
          'label' => '00001.html',
          'hasMimeType' => 'text/html',
          'use' => 'transcription',
          'administrative' => {
            'publish' => false,
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
          'externalIdentifier' => 'http://cocina.sul.stanford.edu/file/223-456-789',
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00001.jp2',
          'label' => '00001.jp2',
          'hasMimeType' => 'image/jp2',
          'administrative' => {
            'publish' => true,
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
          'externalIdentifier' => 'http://cocina.sul.stanford.edu/file/323-456-789',
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00002.html',
          'label' => '00002.html',
          'hasMimeType' => 'text/html',
          'administrative' => {
            'publish' => false,
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
          'externalIdentifier' => 'http://cocina.sul.stanford.edu/file/423-456-789',
          'version' => 1,
          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
          'filename' => '00002.jp2',
          'label' => '00002.jp2',
          'hasMimeType' => 'image/jp2',
          'administrative' => {
            'publish' => true,
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
            'externalIdentifier' => 'http://cocina.sul.stanford.edu/fileSet/234-567-890',
            'version' => 1,
            'type' => 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
            'label' => 'Page 1',
            'structural' => { 'contains' => [file1, file2] }
          },
          {
            'externalIdentifier' => 'http://cocina.sul.stanford.edu/fileSet/334-567-890',
            'version' => 1,
            'type' => 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
            'label' => 'Page 2',
            'structural' => { 'contains' => [file3, file4] }
          }
        ]
      end

      let(:fs1) do
        {
          'type' => 'http://cocina.sul.stanford.edu/models/resources/file.jsonld'
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
              "download":"world",
              "copyright":"All rights reserved unless otherwise indicated.",
              "useAndReproductionStatement":"Property rights reside with the repository..."
            },
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
            "description":{"title":[{"value":"#{title}"}]},
            "identification":#{identification.to_json},"structural":{"contains":#{filesets.to_json}}}
        JSON
      end

      context 'when access match' do
        before do
          # This gives every file and file set the same UUID. In reality, they would be unique.
          allow(SecureRandom).to receive(:uuid).and_return('123-456-789')
        end

        let(:structural) do
          {
            isMemberOf: ['druid:xx888xx7777'],
            contains: [
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/234-567-890', label: 'Page 1', version: 1,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: 'http://cocina.sul.stanford.edu/file/123-456-789',
                      label: '00001.html',
                      filename: '00001.html',
                      size: 0,
                      version: 1,
                      hasMimeType: 'text/html',
                      use: 'transcription',
                      hasMessageDigests: [
                        {
                          type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                        }, {
                          type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                        }
                      ],
                      access: { access: 'dark', download: 'none' },
                      administrative: { publish: false, sdrPreserve: true, shelve: false }
                    }, {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: 'http://cocina.sul.stanford.edu/file/123-456-789',
                      label: '00001.jp2',
                      filename: '00001.jp2',
                      size: 0, version: 1,
                      hasMimeType: 'image/jp2', hasMessageDigests: [],
                      access: { access: 'world', download: 'world' },
                      administrative: { publish: true, sdrPreserve: true, shelve: true }
                    }
                  ]
                }
              }, {
                type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/334-567-890',
                label: 'Page 2', version: 1,
                structural: {
                  contains: [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: 'http://cocina.sul.stanford.edu/file/123-456-789',
                      label: '00002.html', filename: '00002.html', size: 0,
                      version: 1, hasMimeType: 'text/html',
                      hasMessageDigests: [],
                      access: { access: 'dark', download: 'none' },
                      administrative: { publish: false, sdrPreserve: true, shelve: false }
                    }, {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      externalIdentifier: 'http://cocina.sul.stanford.edu/file/123-456-789',
                      label: '00002.jp2',
                      filename: '00002.jp2',
                      size: 0, version: 1,
                      hasMimeType: 'image/jp2',
                      hasMessageDigests: [],
                      access: { access: 'world', download: 'world' },
                      administrative: { publish: true, sdrPreserve: true, shelve: true }
                    }
                  ]
                }
              }
            ]
          }
        end

        it 'creates contentMetadata' do
          patch "/v1/objects/#{druid}",
                params: data,
                headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.body).to equal_cocina_model(expected)
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
          expect(response.status).to eq 400
          expect(response.body).to eq '{"errors":[' \
            '{"status":"400","title":"Bad Request",' \
            '"detail":"Not all files have dark access and/or are unshelved when item access is dark: ' \
            '[\\"00001.jp2\\", \\"00002.html\\", \\"00002.jp2\\"]"}]}'
        end
      end
    end

    context 'when collection is provided' do
      let(:structural) { { isMemberOf: ['druid:xx888xx7777'] } }

      let(:data) do
        <<~JSON
          {
            "externalIdentifier": "#{druid}",
            "type":"http://cocina.sul.stanford.edu/models/image.jsonld",
            "label":"#{label}","version":1,
            "access":{
              "access":"#{access}",
              "download":"world",
              "copyright":"All rights reserved unless otherwise indicated.",
              "useAndReproductionStatement":"Property rights reside with the repository..."
            },
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Google Books"},
            "description":{"title":[{"value":"#{title}"}]},
            "identification":#{identification.to_json},
            "structural":{"isMemberOf":["druid:xx888xx7777"]}}
        JSON
      end

      it 'creates collection relationship' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)
        expect(response.status).to eq(200)
      end
    end
  end

  context 'when a book is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::Vocab.book,
                              label: label,
                              version: 1,
                              description: {
                                title: [{ value: title }],
                                purl: 'http://purl.stanford.edu/gg777gg7777',
                                access: {
                                  digitalRepository: [
                                    { value: 'Stanford Digital Repository' }
                                  ]
                                }
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
                                isMemberOf: ['druid:xx888xx7777']
                              },
                              access: { access: 'world', download: 'world' })
    end
    let(:data) do
      <<~JSON
        {
          "externalIdentifier": "#{druid}",
          "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"#{label}","version":1,
          "access":{
            "access":"world",
            "download":"world"
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"#{title}"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{
            "hasMemberOrders":[{"viewingDirection":"right-to-left"}],
            "isMemberOf":["druid:xx888xx7777"]
          }}
      JSON
    end

    before do
      allow(AdministrativeTags).to receive(:project).and_return([])
    end

    it 'registers the book and sets the viewing direction' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }

      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(200)
    end
  end

  context 'when a collection is provided' do
    let(:item) do
      Dor::Collection.new(pid: druid,
                          label: label,
                          admin_policy_object_id: apo_druid).tap do |item|
        item.descMetadata.title_info.main_title = title
      end
    end

    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected) do
      Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                     label: label,
                                     version: 1,
                                     description: {
                                       title: [{ value: title }],
                                       purl: 'http://purl.stanford.edu/gg777gg7777',
                                       access: {
                                         digitalRepository: [
                                           { value: 'Stanford Digital Repository' }
                                         ]
                                       }
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
          "description":{"title":[{"value":"#{title}"}]}}
      JSON
    end

    before do
      allow(AdministrativeTags).to receive(:project).and_return([])
    end

    it 'creates the collection' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(200)
    end
  end

  context 'when an APO is provided' do
    let(:item) do
      Dor::AdminPolicyObject.new(pid: druid,
                                 label: 'old value').tap do |item|
        item.descMetadata.title_info.main_title = 'This is my title'
        item.administrativeMetadata.default_workflow = 'myWorkflow'
        item.administrativeMetadata.add_default_collection 'druid:gh333qq4444'
      end
    end

    let(:default_object_rights_expected) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>

        <rightsMetadata>
           <access type="discover">
              <machine>
                 <world/>
              </machine>
           </access>
           <access type="read">
              <machine>
                 <location>ars</location>
              </machine>
           </access>
           <use>
              <license>http://opendatacommons.org/licenses/by/1.0/</license>
              <human type="useAndReproduction">Whatever makes you happy</human>
           </use>
           <copyright>
              <human>My copyright statement</human>
           </copyright>
        </rightsMetadata>
      XML
    end

    let(:expected) do
      Cocina::Models::AdminPolicy.new(type: Cocina::Models::Vocab.admin_policy,
                                      label: 'This is my label',
                                      version: 1,
                                      description: {
                                        title: [{ value: 'This is my title' }],
                                        purl: 'http://purl.stanford.edu/gg777gg7777',
                                        access: {
                                          digitalRepository: [
                                            { value: 'Stanford Digital Repository' }
                                          ]
                                        }
                                      },
                                      administrative: {
                                        defaultObjectRights: default_object_rights_expected,
                                        defaultAccess: default_access_expected,
                                        hasAdminPolicy: 'druid:dd999df4567',
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
                                      },
                                      externalIdentifier: druid)
    end

    let(:default_object_rights) { Dor::DefaultObjectRightsDS.new.content }
    let(:default_access) do
      {
        access: 'location-based',
        download: 'location-based',
        readLocation: 'ars',
        copyright: 'My copyright statement',
        license: 'http://opendatacommons.org/licenses/by/1.0/',
        useAndReproductionStatement: 'Whatever makes you happy'
      }
    end
    let(:default_access_expected) { default_access }

    let(:data) do
      <<~JSON
        {
          "externalIdentifier": "#{druid}",
          "type":"http://cocina.sul.stanford.edu/models/admin_policy.jsonld",
          "label":"This is my label","version":1,
          "administrative":{
            "defaultObjectRights":#{default_object_rights.to_json},
            "disseminationWorkflow":"assemblyWF",
            "registrationWorkflow":["goobiWF","registrationWF"],
            "collectionsForRegistration":["druid:gg888df4567","druid:bb888gg4444"],
            "hasAdminPolicy":"druid:dd999df4567",
            "defaultAccess":#{default_access.to_json},
            "roles":[{"name":"dor-apo-manager","members":[{"type":"workgroup","identifier":"sdr:psm-staff"}]}]
          },
          "description":{"title":[{"value":"This is my title"}]}}
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
        expect(response.body).to equal_cocina_model(expected)

        expect(response.status).to eq(200)
      end
    end

    context 'when the request clears out some values' do
      let(:default_access) do
        {
          access: 'world',
          download: 'world',
          readLocation: nil,
          copyright: nil,
          license: nil,
          useAndReproductionStatement: nil
        }
      end

      let(:default_access_expected) { default_access.compact }

      let(:default_object_rights_expected) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>

          <rightsMetadata>
             <access type="discover">
                <machine>
                   <world/>
                </machine>
             </access>
             <access type="read">
                <machine>
                   <world/>
                </machine>
             </access>
          </rightsMetadata>
        XML
      end

      before do
        # This stubs out Solr:
        allow(item).to receive(:admin_policy_object_id).and_return('druid:dd999df4567')
      end

      it 'updates the metadata' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to equal_cocina_model(expected)

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
                                title: [{ value: 'This is my title' }],
                                purl: 'http://purl.stanford.edu/gg777gg7777',
                                access: {
                                  digitalRepository: [
                                    { value: 'Stanford Digital Repository' }
                                  ]
                                }
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
                                isMemberOf: ['druid:xx888xx7777']
                              },
                              access: { access: 'stanford', embargo: { access: 'world', releaseDate: '2020-02-29' } })
    end
    let(:data) do
      <<~JSON
        {
          "externalIdentifier": "#{druid}",
          "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
          "label":"This is my label","version":1,
          "access":{"access":"stanford",
            "embargo":{"access":"world","releaseDate":"2020-02-29"}
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"This is my title"}]},
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end

    before do
      allow(AdministrativeTags).to receive(:project).and_return([])
    end

    it 'registers the book and sets the rights' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(200)
    end
  end
end

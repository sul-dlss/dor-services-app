# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update object' do
  before do
    allow(Dor).to receive(:find).with(druid).and_return(item)
    allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(apo)
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
    allow(Cocina::ObjectValidator).to receive(:validate)

    allow(EventFactory).to receive(:create)
  end

  let(:collection) { Dor::Collection.new(pid: 'druid:xx888xx7777') }
  let(:apo) do
    Cocina::Models::AdminPolicy.new({
                                      cocinaVersion: '0.0.1',
                                      externalIdentifier: apo_druid,
                                      type: Cocina::Models::ObjectType.admin_policy,
                                      label: 'Test Admin Policy',
                                      version: 1,
                                      administrative: {
                                        hasAdminPolicy: 'druid:hy787xj5878',
                                        hasAgreement: 'druid:bb033gt0615',
                                        accessTemplate: { view: 'world', download: 'world' }
                                      }
                                    })
  end
  let!(:item) do
    Dor::Item.new(pid: druid,
                  source_id: 'googlebooks:111111',
                  label: label,
                  admin_policy_object_id: apo_druid).tap do |item|
      item.descMetadata.title_info.main_title = title
      item.contentMetadata.contentType = ['book']
      item.identityMetadata.barcode = '36105036289000'
      item.rightsMetadata.content = Cocina::ToFedora::AccessGenerator.generate(
        root: Dor::RightsMetadataDS.new.ng_xml.root,
        access: cocina_access,
        structural: cocina_structural
      )
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
      isMemberOf: ['druid:xx888xx7777']
    }
  end
  let(:cocina_structural) { Cocina::Models::DROStructural.new(structural) }
  let(:view) { 'world' }
  let(:download) { 'world' }
  let(:cocina_access) do
    Cocina::Models::DROAccess.new(view: view, download: download)
  end
  let(:expected) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::ObjectType.book,
                            label: label,
                            version: 1,
                            access: {
                              copyright: 'All rights reserved unless otherwise indicated.',
                              useAndReproductionStatement: 'Property rights reside with the repository...'
                            }.merge(cocina_access.to_h),
                            description: description,
                            administrative: {
                              hasAdminPolicy: apo_druid
                            },
                            identification: identification,
                            structural: structural)
  end

  let(:description) do
    {
      title: [{ value: title }],
      purl: 'https://purl.stanford.edu/gg777gg7777'
    }
  end

  let(:content_type) { Cocina::Models::ObjectType.book }

  let(:data) do
    <<~JSON
      {
        "cocinaVersion": "0.0.1",
        "externalIdentifier": "#{druid}",
        "type":"#{content_type}",
        "label":"#{label}","version":1,
        "access":{
          "view":"#{view}",
          "download":"#{view}",
          "copyright":"All rights reserved unless otherwise indicated.",
          "useAndReproductionStatement":"Property rights reside with the repository..."
        },
        "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4568"},
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

  it 'updates the object' do
    patch "/v1/objects/#{druid}",
          params: data,
          headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
    expect(response.status).to eq(200)
    expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
    expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
    expect(item).to have_received(:save!)
    expect(item).to have_received(:admin_policy_object_id=).with('druid:dd999df4568')
    expect(Cocina::ObjectValidator).to have_received(:validate)

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
          { type: 'abstract', value: 'test abstract' },
          { type: 'preferred citation', value: 'test citation' },
          { displayLabel: 'Contact', type: 'email', value: 'io@io.io' }
        ],
        purl: 'https://purl.stanford.edu/gg777gg7777'
      }
    end

    let(:expected) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.book,
                              label: label,
                              version: 1,
                              access: {
                                view: view,
                                download: 'world',
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: description,
                              administrative: {
                                hasAdminPolicy: apo_druid
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
        expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
        expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
        expect(item).to have_received(:save!)
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
        ],
        purl: 'https://purl.stanford.edu/gg777gg7777'
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
    let(:cocina_access) do
      Cocina::Models::DROAccess.new(view: view, download: view)
    end

    let(:expected) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.book,
                              label: label,
                              version: 1,
                              access: {
                                view: view,
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
                                purl: 'https://purl.stanford.edu/gg777gg7777'
                              },
                              administrative: {
                                hasAdminPolicy: apo_druid
                              },
                              identification: identification,
                              structural: structural)
    end
    let(:data) do
      <<~JSON
        {
          "cocinaVersion": "0.0.1",
          "externalIdentifier": "#{druid}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"#{label}","version":1,
          "access":{
            "view":"#{view}",
            "download":"world",
            "copyright":"All rights reserved unless otherwise indicated.",
            "useAndReproductionStatement":"Property rights reside with the repository..."
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{
            "title":[{"structuredValue":[{"value":"#{title}","type":"main title"},{"value":"(repeat)","type":"subtitle"}]}],
            "purl":"https://purl.stanford.edu/gg777gg7777"
          },
          "identification":#{identification.to_json},
          "structural":{
            "hasMemberOrders":[{"viewingDirection":"right-to-left"}],
            "isMemberOf":["druid:xx888xx7777"]
          }
        }
      JSON
    end
    let!(:item) do
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
        item.rightsMetadata.content = Cocina::ToFedora::AccessGenerator.generate(
          root: Dor::RightsMetadataDS.new.ng_xml.root,
          access: cocina_access
        )
      end
    end

    it 'updates the object' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
      expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
      expect(item).to have_received(:save!)
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
        item.rightsMetadata.content = Cocina::ToFedora::AccessGenerator.generate(
          root: Dor::RightsMetadataDS.new.ng_xml.root,
          access: cocina_access
        )
      end
    end

    let(:title) { 'Hydrus' } # The title in the request (data)
    let(:label) { 'Hydrus' } # This is the label in the request (data)

    it 'updates the object' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
      expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
      expect(item).to have_received(:save!)
    end
  end

  context 'when tags change' do
    # In other tests, viewing direction starts at and remains right-to-left.
    # For this test, starting at left-to-right and changing to right-to-left.
    before do
      allow(AdministrativeTags).to receive(:for).and_return(['Project : Tom Swift', 'Process : Content Type : Book (ltr)'])
      allow(AdministrativeTags).to receive(:content_type).and_return(['Book (ltr)'], ['Book (rtl)'])
      allow(AdministrativeTags).to receive(:update)
    end

    it 'updates the object and the tags' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
      expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
      expect(item).to have_received(:save!)

      # Tags are updated.
      expect(AdministrativeTags).not_to have_received(:create)
      expect(AdministrativeTags).to have_received(:update).with(identifier: druid, current: 'Process : Content Type : Book (ltr)', new: 'Process : Content Type : Book (rtl)')
    end
  end

  context 'when tags do not change' do
    before do
      allow(AdministrativeTags).to receive(:for).and_return(['Project : EEMS', 'Process : Content Type : Book (rtl)'])
    end

    it 'updates the object but not the tags' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
      expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
      expect(item).to have_received(:save!)

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
    end
  end

  context 'when updated cocina cannot be mapped' do
    # Geo content type without geographic.
    let(:content_type) { Cocina::Models::ObjectType.geo }

    it 'is a bad request and does not save' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(422)
      expect(item).not_to have_received(:save!)
    end
  end

  context 'when validation fails' do
    before do
      allow(Cocina::ObjectValidator).to receive(:validate).and_raise(Cocina::ValidationError, 'Not on my watch.')
    end

    it 'is a bad request' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(400)
      expect(item).not_to have_received(:save!)
    end
  end

  context 'when title changes' do
    let(:description) do
      {
        title: [{ value: 'Not a title' }],
        purl: 'https://purl.stanford.edu/gg777gg7777'
      }
    end

    it 'returns the updated object' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(response.body).to include('Not a title')
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
    let(:view) { 'world' }
    let(:expected) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.image,
                              label: expected_label,
                              version: 1,
                              access: {
                                view: view,
                                download: 'world',
                                copyright: 'All rights reserved unless otherwise indicated.',
                                useAndReproductionStatement: 'Property rights reside with the repository...'
                              },
                              description: {
                                title: [{ value: title }],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:dd999df4567'
                              },
                              identification: identification,
                              structural: structural)
    end
    let(:data) do
      <<~JSON
        {
          "cocinaVersion": "0.0.1",
          "externalIdentifier": "#{druid}",
          "type":"#{Cocina::Models::ObjectType.image}",
          "label":"#{expected_label}","version":1,
          "access":{
            "view":"#{view}",
            "download":"world",
            "copyright":"All rights reserved unless otherwise indicated.",
            "useAndReproductionStatement":"Property rights reside with the repository..."
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{
            "title":[{"value":"#{title}"}],
            "purl":"https://purl.stanford.edu/gg777gg7777"
          },
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
        expect(response.status).to eq 200
        expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
        expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)

        # Identity metadata set correctly.
        expect(item.objectLabel.first).to eq(expected_label)
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
        expect(response.status).to eq(200)
        expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
        expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
      end
    end
    # rubocop:enable Layout/LineLength

    context 'when files are provided' do
      let(:file1) do
        {
          'externalIdentifier' => 'https://cocina.sul.stanford.edu/file/123-456-789',
          'version' => 1,
          'type' => Cocina::Models::ObjectType.file,
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
          'externalIdentifier' => 'https://cocina.sul.stanford.edu/file/223-456-789',
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
          'externalIdentifier' => 'https://cocina.sul.stanford.edu/file/323-456-789',
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
            'view' => 'world',
            'download' => 'world'
          },
          'hasMessageDigests' => []
        }
      end

      let(:file4) do
        {
          'externalIdentifier' => 'https://cocina.sul.stanford.edu/file/423-456-789',
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

      let(:filesets) do
        [
          {
            'externalIdentifier' => 'https://cocina.sul.stanford.edu/fileSet/234-567-890',
            'version' => 1,
            'type' => Cocina::Models::FileSetType.file,
            'label' => 'Page 1',
            'structural' => { 'contains' => [file1, file2] }
          },
          {
            'externalIdentifier' => 'https://cocina.sul.stanford.edu/fileSet/334-567-890',
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
            "cocinaVersion": "0.0.1",
            "externalIdentifier": "#{druid}",
            "type":"#{Cocina::Models::ObjectType.image}",
            "label":"#{label}","version":1,
            "access":{
              "view":"#{view}",
              "download":"world",
              "copyright":"All rights reserved unless otherwise indicated.",
              "useAndReproductionStatement":"Property rights reside with the repository..."
            },
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
            "description":{
              "title":[{"value":"#{title}"}],
              "purl":"https://purl.stanford.edu/gg777gg7777"
            },
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
                type: Cocina::Models::FileSetType.file,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777-234-567-890', label: 'Page 1', version: 1,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777-234-567-890/00001.html',
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
                      access: { view: 'dark', download: 'none' },
                      administrative: { publish: false, sdrPreserve: true, shelve: false }
                    }, {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777-234-567-890/00001.jp2',
                      label: '00001.jp2',
                      filename: '00001.jp2',
                      size: 0, version: 1,
                      hasMimeType: 'image/jp2', hasMessageDigests: [],
                      access: { view: 'world', download: 'world' },
                      administrative: { publish: true, sdrPreserve: true, shelve: true }
                    }
                  ]
                }
              }, {
                type: Cocina::Models::FileSetType.file,
                externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/gg777gg7777-334-567-890',
                label: 'Page 2', version: 1,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777-334-567-890/00002.html',
                      label: '00002.html', filename: '00002.html', size: 0,
                      version: 1, hasMimeType: 'text/html',
                      hasMessageDigests: [],
                      access: { view: 'dark', download: 'none' },
                      administrative: { publish: false, sdrPreserve: true, shelve: false }
                    }, {
                      type: Cocina::Models::ObjectType.file,
                      externalIdentifier: 'https://cocina.sul.stanford.edu/file/gg777gg7777-334-567-890/00002.jp2',
                      label: '00002.jp2',
                      filename: '00002.jp2',
                      size: 0, version: 1,
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

        it 'creates contentMetadata' do
          patch "/v1/objects/#{druid}",
                params: data,
                headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.status).to eq(200)
          expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
          expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
          expect(item.contentMetadata.resource.file.count).to eq 4
        end
      end

      context 'when access mismatch' do
        let(:view) { 'dark' }
        let(:download) { 'none' }

        it 'returns 400' do
          patch "/v1/objects/#{druid}",
                params: data,
                headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
          expect(response.status).to eq 400
        end
      end
    end

    context 'when collection is provided' do
      let(:structural) { { isMemberOf: ['druid:xx888xx7777'] } }

      let(:data) do
        <<~JSON
          {
            "cocinaVersion":"0.0.1",
            "externalIdentifier": "#{druid}",
            "type":"#{Cocina::Models::ObjectType.image}",
            "label":"#{label}","version":1,
            "access":{
              "view":"#{view}",
              "download":"world",
              "copyright":"All rights reserved unless otherwise indicated.",
              "useAndReproductionStatement":"Property rights reside with the repository..."
            },
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
            "description":{
              "title":[{"value":"#{title}"}],
              "purl":"https://purl.stanford.edu/gg777gg7777"
            },
            "identification":#{identification.to_json},
            "structural":{"isMemberOf":["druid:xx888xx7777"]}}
        JSON
      end

      it 'creates collection relationship' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(200)
        expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
        expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
      end
    end
  end

  context 'when a book is provided' do
    let(:label) { 'This is my label' }
    let(:title) { 'This is my title' }
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.book,
                              label: label,
                              version: 1,
                              description: {
                                title: [{ value: title }],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
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
                              access: { view: 'world', download: 'world' })
    end
    let(:data) do
      <<~JSON
        {
          "cocinaVersion": "0.0.1",
          "externalIdentifier": "#{druid}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"#{label}","version":1,
          "access":{
            "view":"world",
            "download":"world"
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{
            "title":[{"value":"#{title}"}],
            "purl":"https://purl.stanford.edu/gg777gg7777"
          },
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

      expect(response.status).to eq(200)
      expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
      expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
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
      Cocina::Models::Collection.new(type: Cocina::Models::ObjectType.collection,
                                     label: label,
                                     version: 1,
                                     description: {
                                       title: [{ value: title }],
                                       purl: 'https://purl.stanford.edu/gg777gg7777'
                                     },
                                     identification: identification,
                                     administrative: {
                                       hasAdminPolicy: 'druid:dd999df4567'
                                     },
                                     externalIdentifier: druid,
                                     access: {})
    end
    let(:identification) do
      {
        catalogLinks: [
          { catalog: 'symphony', catalogRecordId: '8888' }
        ]
      }
    end

    let(:data) do
      <<~JSON
        {
          "cocinaVersion": "0.0.1",
          "externalIdentifier": "#{druid}",
          "type":"#{Cocina::Models::ObjectType.collection}",
          "label":"#{label}","version":1,
          "access":{},
          "identification":#{identification.to_json},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{
            "title":[{"value":"#{title}"}],
            "purl":"https://purl.stanford.edu/gg777gg7777"
          }
        }
      JSON
    end

    before do
      allow(AdministrativeTags).to receive(:project).and_return([])
    end

    it 'creates the collection' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
      expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
    end
  end

  context 'when an APO is provided' do
    let(:item) do
      Dor::AdminPolicyObject.new(pid: druid,
                                 label: 'old value').tap do |item|
        item.descMetadata.title_info.main_title = 'This is my title'
        item.administrativeMetadata.default_workflow = 'myWorkflow'
        item.administrativeMetadata.add_default_collection 'druid:gh333qq4444'
        item.identityMetadata.objectLabel = 'my original objectLabel'
      end
    end

    let(:expected) do
      Cocina::Models::AdminPolicy.new(type: Cocina::Models::ObjectType.admin_policy,
                                      label: 'This is my label',
                                      version: 1,
                                      description: {
                                        title: [{ value: 'This is my title' }],
                                        purl: 'https://purl.stanford.edu/gg777gg7777'
                                      },
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
                                      },
                                      externalIdentifier: druid)
    end

    let(:default_access) do
      {
        view: 'location-based',
        download: 'location-based',
        location: 'ars',
        copyright: 'My copyright statement',
        license: 'http://opendatacommons.org/licenses/by/1.0/',
        useAndReproductionStatement: 'Whatever makes you happy'
      }
    end
    let(:default_access_expected) { default_access }

    let(:data) do
      <<~JSON
        {
          "cocinaVersion": "0.0.1",
          "externalIdentifier": "#{druid}",
          "type":"#{Cocina::Models::ObjectType.admin_policy}",
          "label":"This is my label","version":1,
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
            "purl":"https://purl.stanford.edu/gg777gg7777"
          }
        }
      JSON
    end

    context 'when the request is successful' do
      before do
        # This stubs out Solr:
        allow(item).to receive(:admin_policy_object_id).and_return('druid:dd999df4567')
        allow(item).to receive(:agreement_object_id).and_return('druid:bc123df4567')
      end

      it 'registers the object with the registration service' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(200)
        expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
        expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
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

      let(:default_access_expected) { default_access.compact }

      before do
        # This stubs out Solr:
        allow(item).to receive(:admin_policy_object_id).and_return('druid:dd999df4567')
        allow(item).to receive(:agreement_object_id).and_return('druid:bc123df4567')
      end

      it 'updates the metadata' do
        patch "/v1/objects/#{druid}",
              params: data,
              headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.status).to eq(200)
        expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
        expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
      end
    end
  end

  context 'when an embargo is provided' do
    let(:expected) do
      Cocina::Models::DRO.new(type: Cocina::Models::ObjectType.book,
                              label: 'This is my label',
                              version: 1,
                              description: {
                                title: [{ value: 'This is my title' }],
                                purl: 'https://purl.stanford.edu/gg777gg7777'
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
                              access: {
                                view: 'stanford',
                                download: 'stanford',
                                embargo: {
                                  view: 'world',
                                  download: 'world',
                                  releaseDate: '2020-02-29'
                                }
                              })
    end
    let(:data) do
      <<~JSON
        {
          "cocinaVersion": "0.0.1",
          "externalIdentifier": "#{druid}",
          "type":"#{Cocina::Models::ObjectType.book}",
          "label":"This is my label","version":1,
          "access":{"view":"stanford","download":"stanford",
            "embargo":{"view":"world","download":"world","releaseDate":"2020-02-29"}
          },
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{
            "title":[{"value":"This is my title"}],
            "purl":"https://purl.stanford.edu/gg777gg7777"
          },
          "identification":{"sourceId":"googlebooks:999999"},
          "structural":{"hasMemberOrders":[{"viewingDirection":"right-to-left"}]}}
      JSON
    end
    let(:view) { 'stanford' }
    let(:download) { 'stanford' }

    before do
      allow(AdministrativeTags).to receive(:project).and_return([])
    end

    it 'registers the book and sets the rights' do
      patch "/v1/objects/#{druid}",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.status).to eq(200)
      expect(response.body).to equal_cocina_model(Cocina::Models.build(JSON.parse(data)))
      expect(Cocina::Mapper.build(item).to_json).to equal_cocina_model(expected)
    end
  end
end

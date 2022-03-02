# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create object' do
  let(:minimal_cocina_admin_policy) do
    Cocina::Models::AdminPolicy.new({
                                      cocinaVersion: '0.0.1',
                                      externalIdentifier: 'druid:dd999df4567',
                                      type: Cocina::Models::Vocab.admin_policy,
                                      label: 'Test Admin Policy',
                                      version: 1,
                                      administrative: {
                                        hasAdminPolicy: 'druid:hy787xj5878',
                                        hasAgreement: 'druid:bb033gt0615',
                                        defaultAccess: {
                                          access: 'world',
                                          download: 'world'
                                        }
                                      }
                                    })
  end
  let(:label) { 'This is my label' }
  let(:title) { 'This is my title' }
  let(:expected_label) { label }
  let(:druid) { 'druid:gg777gg7777' }

  before do
    allow(SuriService).to receive(:mint_id).and_return(druid)
    allow_any_instance_of(CocinaObjectStore).to receive(:find).with('druid:dd999df4567').and_return(minimal_cocina_admin_policy)
    allow(Cocina::ActiveFedoraPersister).to receive(:store)
    stub_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')
  end

  context 'when the catkey is provided and save is successful' do
    let(:expected_label) { title } # label derived from catalog data
    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"0.0.1",
          "type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
          "label":"#{label}","version":1,"access":{"access":"world"},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"#{title}"}]},
          "identification":#{identification.to_json}}
      JSON
    end

    let(:expected) do
      Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                     label: expected_label,
                                     version: 1,
                                     description: {
                                       title: [{ value: title }],
                                       purl: 'https://purl.stanford.edu/gg777gg7777'
                                     },
                                     administrative: {
                                       hasAdminPolicy: 'druid:dd999df4567'
                                     },
                                     identification: identification,
                                     externalIdentifier: druid,
                                     access: {
                                       access: 'world'
                                     })
    end

    let(:identification) do
      {
        catalogLinks: [
          { catalog: 'symphony', catalogRecordId: '8888' }
        ]
      }
    end
    let(:mods_from_symphony) do
      <<~XML
        <mods xmlns:xlink="http://www.w3.org/1999/xlink"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xmlns="http://www.loc.gov/mods/v3" version="3.3"
              xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
          <titleInfo>
            <title>#{title}</title>
          </titleInfo>
        </mods>
      XML
    end

    before do
      allow(MetadataService).to receive(:fetch).and_return(mods_from_symphony)
    end

    it 'creates the collection' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
      expect(response.location).to eq "/v1/objects/#{druid}"
      expect(MetadataService).to have_received(:fetch).with('catkey:8888')
    end
  end

  context 'when the catkey is not provided and save is successful' do
    let(:expected) do
      Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                     label: expected_label,
                                     version: 1,
                                     description: {
                                       title: [{ value: title }],
                                       purl: 'https://purl.stanford.edu/gg777gg7777'
                                     },
                                     identification: {
                                       sourceId: 'hydrus:collection-456'
                                     },
                                     administrative: {
                                       hasAdminPolicy: 'druid:dd999df4567',
                                       partOfProject: 'Hydrus'
                                     },
                                     externalIdentifier: druid,
                                     access: {
                                       access: 'world'
                                     })
    end

    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"0.0.1",
          "type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
          "label":"#{label}","version":1,"access":{"access":"world"},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Hydrus"},
          "identification":{"sourceId":"hydrus:collection-456"},
          "description":{"title":[{"value":"#{title}"}]}
        }
      JSON
    end

    it 'creates the collection' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
      expect(response.location).to eq "/v1/objects/#{druid}"
    end
  end

  context 'when a description including summary note (abstract) is provided' do
    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"0.0.1",
          "type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
          "label":"#{label}",
          "version":1,
          "access":{"access":"world"},
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
          "description":{
            "title":[{"value":"#{title}"}],
            "note":[{"value":"coll abstract","type":"abstract"}]
            }
          }
      JSON
    end
    let(:expected) do
      Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                     label: expected_label,
                                     version: 1,
                                     access: { access: 'world' },
                                     administrative: {
                                       hasAdminPolicy: 'druid:dd999df4567'
                                     },
                                     description: {
                                       title: [{ value: title }],
                                       note: [{ value: 'coll abstract', type: 'abstract' }],
                                       purl: Purl.for(druid: druid)
                                     },
                                     externalIdentifier: druid)
    end

    it 'creates the collection with populated description title and note' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
      expect(response.location).to eq "/v1/objects/#{druid}"
    end
  end

  context 'when access is provided' do
    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"0.0.1",
          "type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
          "label":"#{label}",
          "version":1,
          "access":{ "access": "world" },
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"}
          }
      JSON
    end
    let(:expected) do
      Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                     label: expected_label,
                                     version: 1,
                                     access: { access: 'world' },
                                     administrative: {
                                       hasAdminPolicy: 'druid:dd999df4567'
                                     },
                                     description: {
                                       title: [{ value: expected_label }],
                                       purl: 'https://purl.stanford.edu/gg777gg7777'
                                     },
                                     externalIdentifier: druid)
    end

    it 'creates the collection with populated access' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response.status).to eq(201)
      expect(response.location).to eq "/v1/objects/#{druid}"
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create object' do
  let(:apo) { Dor::AdminPolicyObject.new(pid: 'druid:dd999df4567') }
  let(:data) { item.to_json }
  let(:druid) { 'druid:gg777gg7777' }

  before do
    allow(Dor::SuriService).to receive(:mint_id).and_return(druid)
    allow(Dor).to receive(:find).and_return(apo)
    allow(Cocina::ActiveFedoraPersister).to receive(:store)
    stub_request(:post, 'https://dor-indexing-app.example.edu/dor/reindex/druid:gg777gg7777')
  end

  context 'when a collection is provided' do
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
                                       hasAdminPolicy: 'druid:dd999df4567',
                                       partOfProject: 'Hydrus'
                                     },
                                     externalIdentifier: druid,
                                     access: {})
    end
    let(:data) do
      <<~JSON
        {"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
          "label":"#{label}","version":1,"access":{},
          "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Hydrus"},
          "description":{"title":[{"status":"primary","value":"#{title}"}]}}
      JSON
    end

    context 'when the catkey is provided and save is successful' do
      let(:expected_label) { title } # label derived from catalog data
      let(:data) do
        <<~JSON
          {"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
            "label":"#{label}","version":1,"access":{},
            "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
            "description":{"title":[{"status":"primary","value":"#{title}"}]},
            "identification":#{identification.to_json}}
        JSON
      end

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
                                       identification: identification,
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
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
        expect(MetadataService).to have_received(:fetch).with('catkey:8888')
      end
    end

    context 'when the catkey is not provided and save is successful' do
      it 'creates the collection' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json

        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end

    context 'when a description including summary note (abstract) is provided' do
      let(:data) do
        <<~JSON
          {"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
            "label":"#{label}",
            "version":1,
            "access":{},
            "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
            "description":{
              "title":[{"status":"primary","value":"#{title}"}],
              "note":[{"value":"coll abstract","type":"summary"}]
              }
            }
        JSON
      end
      let(:expected) do
        Cocina::Models::Collection.new(type: Cocina::Models::Vocab.collection,
                                       label: expected_label,
                                       version: 1,
                                       access: { access: 'dark', download: 'none' },
                                       administrative: {
                                         hasAdminPolicy: 'druid:dd999df4567'
                                       },
                                       description: {
                                         title: [{ value: title, status: 'primary' }],
                                         note: [{ value: 'coll abstract', type: 'summary' }]
                                       },
                                       externalIdentifier: druid)
      end

      it 'creates the collection with populated description title and note' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end

    context 'when access is provided' do
      let(:data) do
        <<~JSON
          {"type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
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
                                       access: { access: 'world', download: 'none' },
                                       administrative: {
                                         hasAdminPolicy: 'druid:dd999df4567'
                                       },
                                       description: {
                                         title: [{ value: expected_label, status: 'primary' }]
                                       },
                                       externalIdentifier: druid)
      end

      it 'creates the collection with populated access' do
        post '/v1/objects',
             params: data,
             headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
        expect(response.body).to eq expected.to_json
        expect(response.status).to eq(201)
        expect(response.location).to eq "/v1/objects/#{druid}"
      end
    end
  end
end

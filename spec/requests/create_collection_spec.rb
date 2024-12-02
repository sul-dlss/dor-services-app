# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create object' do
  let(:minimal_cocina_admin_policy) do
    build(:admin_policy, id: 'druid:dd999df4567')
  end
  let(:label) { 'This is my label' }
  let(:title) { 'This is my title' }
  let(:expected_label) { label }
  let(:druid) { 'druid:gg777gg7777' }

  before do
    allow(SuriService).to receive(:mint_id).and_return(druid)
    allow_any_instance_of(CocinaObjectStore).to receive(:find).with('druid:dd999df4567').and_return(minimal_cocina_admin_policy)
    allow(Indexer).to receive(:reindex)
  end

  context 'when the folio instance hrid is provided and save is successful' do
    let(:expected_label) { title } # label derived from catalog data
    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.collection}",
          "label":"#{label}","version":1,"access":{"view":"world"},
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
          "description":{"title":[{"value":"#{title}"}]},
          "identification":#{identification.to_json}}
      JSON
    end

    let(:expected) do
      build(:collection, id: druid, label: expected_label, title:, admin_policy_id: 'druid:dd999df4567').new(
        identification:,
        access: {
          view: 'world'
        }
      )
    end

    let(:identification) do
      {
        catalogLinks: [
          { catalog: 'folio', catalogRecordId: 'a8888', refresh: true }
        ]
      }
    end
    let(:mods) do
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

    let(:marc_service) do
      instance_double(Catalog::MarcService, mods:, mods_ng: Nokogiri::XML(mods))
    end

    before do
      allow(Catalog::MarcService).to receive(:new).and_return(marc_service)
    end

    it 'creates the collection' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response).to have_http_status(:created)
      expect(response.location).to eq "/v1/objects/#{druid}"
      expect(Catalog::MarcService).to have_received(:new).with(folio_instance_hrid: 'a8888')
    end
  end

  context 'when the folio instance hrid is not provided and save is successful' do
    let(:expected) do
      build(:collection, id: druid, label: expected_label, title:, admin_policy_id: 'druid:dd999df4567').new(
        identification: {
          sourceId: 'hydrus:collection-456'
        },
        access: {
          view: 'world'
        }
      )
    end

    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.collection}",
          "label":"#{label}","version":1,"access":{"view":"world"},
          "administrative":{"hasAdminPolicy":"druid:dd999df4567","partOfProject":"Hydrus"},
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
      expect(response).to have_http_status(:created)
      expect(response.location).to eq "/v1/objects/#{druid}"
    end
  end

  context 'when a description including summary note (abstract) is provided' do
    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.collection}",
          "label":"#{label}",
          "version":1,
          "access":{"view":"world"},
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
          "description":{
            "title":[{"value":"#{title}"}],
            "note":[{"value":"coll abstract","type":"abstract"}]
            },
          "identification": {"sourceId": "sulcollection:1234"}
          }

      JSON
    end
    let(:expected) do
      build(:collection, id: druid, label: expected_label, title:, admin_policy_id: 'druid:dd999df4567').new(
        access: {
          view: 'world'
        },
        description: {
          title: [{ value: title }],
          note: [{ value: 'coll abstract', type: 'abstract' }],
          purl: Purl.for(druid:)
        }
      )
    end

    it 'creates the collection with populated description title and note' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response).to have_http_status(:created)
      expect(response.location).to eq "/v1/objects/#{druid}"
    end
  end

  context 'when access is provided' do
    let(:data) do
      <<~JSON
        {
          "cocinaVersion":"#{Cocina::Models::VERSION}",
          "type":"#{Cocina::Models::ObjectType.collection}",
          "label":"#{label}",
          "version":1,
          "access":{ "view": "world" },
          "administrative":{"hasAdminPolicy":"druid:dd999df4567"},
          "identification":{ "sourceId": "sulcollection:1234" }
          }
      JSON
    end
    let(:expected) do
      build(:collection, id: druid, label: expected_label, title: expected_label, admin_policy_id: 'druid:dd999df4567').new(
        access: {
          view: 'world'
        }
      )
    end

    it 'creates the collection with populated access' do
      post '/v1/objects',
           params: data,
           headers: { 'Authorization' => "Bearer #{jwt}", 'Content-Type' => 'application/json' }
      expect(response.body).to equal_cocina_model(expected)
      expect(response).to have_http_status(:created)
      expect(response.location).to eq "/v1/objects/#{druid}"
    end
  end
end

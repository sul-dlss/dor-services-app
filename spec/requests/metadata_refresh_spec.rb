# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh metadata' do
  include Dry::Monads[:result]

  let(:druid) { 'druid:bc753qt7345' }
  let(:apo_druid) { 'druid:pp000pp0000' }
  let(:description) do
    {
      title: [{ value: 'However am I going to be' }],
      purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
    }
  end
  let(:identification) do
    {
      catalogLinks: [{
        catalog: 'folio',
        catalogRecordId: 'a10121797',
        refresh: true
      }],
      sourceId: 'sul:123'
    }
  end
  let(:cocina_object) do
    build(:dro, id: druid, label: 'A new map of Africa', admin_policy_id: apo_druid).new(identification:, description:)
  end
  let(:today) { Time.zone.today.iso8601 }

  let(:updated_cocina_object) do
    build(:dro, id: druid, label: 'A new map of Africa', admin_policy_id: apo_druid).new(
      identification:,
      description: {
        title: [{ value: 'Paying for College' }],
        purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}",
        adminMetadata: {
          note: [
            {
              type: 'record origin',
              value: "Converted from MARC to Cocina #{today}"
            }
          ]
        }
      }
    )
  end
  let(:cocina_apo_object) { build(:admin_policy, id: apo_druid) }

  let(:marc) do
    { fields: [
      { '245': {
        ind1: '1',
        ind2: '0',
        subfields: [
          {
            a: 'Paying for College'
          }
        ]
      } }
    ] }.deep_stringify_keys
  end

  let(:marc_service) do
    instance_double(Catalog::MarcService, marc:)
  end

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(cocina_apo_object)
    allow(UpdateObjectService).to receive(:update).and_return(updated_cocina_object)
    allow(Catalog::MarcService).to receive(:new).and_return(marc_service)
    allow(marc_service).to receive(:marc_record).and_return(marc)
  end

  context 'when happy path' do
    it 'updates the metadata and saves the changes' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(UpdateObjectService).to have_received(:update).with(cocina_object: updated_cocina_object)
    end
  end

  context 'when the cocina object only has a barcode' do
    let(:identification) do
      {
        barcode: '36105216275185',
        sourceId: 'sul:123'
      }
    end

    it 'updates the metadata and saves the changes' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(UpdateObjectService).to have_received(:update).with(cocina_object: updated_cocina_object)
    end
  end

  context 'with a collection' do
    let(:cocina_object) do
      build(:collection, id: druid)
    end

    it 'returns a 422 error' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to match("#{druid} has no catalog links marked as refreshable")
    end
  end

  describe 'errors in response from catalog' do
    let(:identification) do
      {
        catalogLinks: [{
          catalog: 'folio',
          catalogRecordId: 'a666',
          refresh: true
        }],
        sourceId: 'sul:123'
      }
    end

    let(:marc_service) { instance_double(Catalog::MarcService) }

    context 'when folio instance hrid not found' do
      before do
        allow(marc_service).to receive(:marc).and_raise(Catalog::MarcService::CatalogRecordNotFoundError)
      end

      it 'returns a 400 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
        expect(json.dig('errors', 0, 'title')).to eq 'Not found in catalog'
      end
    end

    context 'when HTTP error' do
      let(:err_body) do
        {
          messageList: [
            {
              code: 'oops',
              message: 'Something somewhere went wrong.'
            }
          ]
        }
      end

      before do
        allow(marc_service).to receive(:marc).and_raise(Catalog::MarcService::CatalogResponseError,
                                                        'Something went wrong')
      end

      it 'returns a 500 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to match('Something went wrong')
      end
    end

    context 'when Cocina validation error' do
      let(:result) { Success(RefreshDescriptionFromCatalog::Result.new(description_props, nil)) }
      let(:description_props) do
        # Missing title
        {
          purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
        }
      end

      before do
        allow(RefreshDescriptionFromCatalog).to receive(:run).and_return(result)
      end

      it 'returns a 422 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to match('missing required properties: title')
      end
    end
  end
end

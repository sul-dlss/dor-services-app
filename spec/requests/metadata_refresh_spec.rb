# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh metadata' do
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
        catalog: 'symphony',
        catalogRecordId: '10121797',
        refresh: true
      }],
      sourceId: 'sul:123'
    }
  end
  let(:cocina_object) do
    build(:dro, id: druid, label: 'A new map of Africa', admin_policy_id: apo_druid).new(identification:, description:)
  end
  let(:updated_cocina_object) do
    build(:dro, id: druid, label: 'A new map of Africa', admin_policy_id: apo_druid).new(
      identification:,
      description: {
        title: [{ value: 'Paying for College', status: 'primary' }],
        purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}",
        adminMetadata: {
          note: [
            {
              type: 'record origin',
              value: "Converted from MARCXML to MODS version 3.7 using\n\t\t\t\t" \
                     "MARC21slim2MODS3-7_SDR_v2-7.xsl (SUL 3.7 version 2.7 20220901; LC Revision 1.140\n\t\t\t\t" \
                     '20200717)'
            }
          ]
        }
      }
    )
  end
  let(:cocina_apo_object) { build(:admin_policy, id: apo_druid) }

  let(:marc) do
    MARC::Record.new.tap do |record|
      record << MARC::DataField.new('245', '0', ' ', ['a', 'Paying for College'])
    end
  end

  let(:marc_service) { Catalog::MarcService.new }

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
      expect(UpdateObjectService).to have_received(:update).with(updated_cocina_object)
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
      expect(UpdateObjectService).to have_received(:update).with(updated_cocina_object)
    end
  end

  context 'with a collection' do
    let(:cocina_object) do
      build(:collection, id: druid)
    end

    it 'returns a 422 error' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match("#{druid} has no catalog links marked as refreshable")
    end
  end

  describe 'errors in response from catalog' do
    let(:identification) do
      {
        catalogLinks: [{
          catalog: 'symphony',
          catalogRecordId: '666',
          refresh: true
        }],
        sourceId: 'sul:123'
      }
    end

    let(:marc_service) { instance_double(Catalog::MarcService) }

    context 'when catkey not found' do
      before do
        allow(marc_service).to receive(:mods).and_raise(Catalog::MarcService::CatalogRecordNotFoundError)
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
        allow(marc_service).to receive(:mods).and_raise(Catalog::MarcService::CatalogResponseError, 'Something went wrong')
      end

      it 'returns a 500 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to match('Something went wrong')
      end
    end

    context 'when transform error' do
      let(:xslt) { instance_double(Nokogiri::XSLT::Stylesheet) }

      let(:marc_service) { Catalog::MarcService.new(barcode: '1234') }

      before do
        allow(marc_service).to receive(:marc_record).and_return(MARC::Record.new)
        allow(Nokogiri).to receive(:XSLT).and_return(xslt)
        allow(xslt).to receive(:transform).and_raise(RuntimeError, 'Cannot add attributes to an element if children have been already added to the element.')
      end

      it 'returns a 500 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to match('Cannot add attributes to an element if children have been already added to the element.')
      end
    end
  end
end

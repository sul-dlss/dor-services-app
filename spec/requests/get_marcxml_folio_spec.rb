# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Looking up an item's marcxml (Folio)" do
  let(:barcode) { '101' }
  let(:folio_instance_hrid) { 'a12345' }
  let(:marc_record) do
    MARC::Record.new_from_hash(marc_hash)
  end
  let(:marc_hash) do
    {
      'fields' => [
        { '001' => folio_instance_hrid },
        { '003' => 'FOLIO' },
        { '245' =>
          { 'ind1' => '4',
            'ind2' => '1',
            'subfields' =>
            [{ 'a' => 'some data' }] } }
      ],
      'leader' => '00956cem 2200229Ma 4500'
    }
  end

  context 'when looking up an item by folio_instance_id' do
    before do
      allow(Catalog::FolioReader).to receive(:to_marc).and_return(marc_record)
    end

    it 'return marcxml' do
      get "/v1/catalog/marcxml?folio_instance_hrid=#{folio_instance_hrid}", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.body).to start_with "<?xml version=\"1.0\"?>\n<record xmlns=\"http://www.loc.gov/MARC21/slim\">"
      expect(Catalog::FolioReader).to have_received(:to_marc).with(folio_instance_hrid:, barcode: nil)
    end
  end

  context 'when looking up an item by barcode' do
    before do
      allow(Catalog::FolioReader).to receive(:to_marc).and_return(marc_record)
    end

    it 'return marcxml' do
      get "/v1/catalog/marcxml?barcode=#{barcode}", headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response.body).to start_with "<?xml version=\"1.0\"?>\n<record xmlns=\"http://www.loc.gov/MARC21/slim\">"
      expect(Catalog::FolioReader).to have_received(:to_marc).with(folio_instance_hrid: nil, barcode:)
    end
  end

  describe 'errors in response from Folio' do
    context 'when HRID not found' do
      before do
        allow(Catalog::FolioReader).to receive(:to_marc).and_raise(FolioClient::ResourceNotFound)
      end

      it 'returns a 400 error when fetching marcxml' do
        get "/v1/catalog/marcxml?folio_instance_hrid=#{folio_instance_hrid}", headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
        expect(json.dig('errors', 0, 'title')).to eq 'Record not found in catalog'
      end
    end

    context 'when other HTTP error' do
      before do
        allow(Catalog::FolioReader).to receive(:to_marc).and_raise(FolioClient::ServiceUnavailable)
      end

      it 'returns a 500 error' do
        get "/v1/catalog/marcxml?folio_instance_hrid=#{folio_instance_hrid}", headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:internal_server_error)
        json = JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
        expect(json.dig('errors', 0, 'title')).to eq 'Internal Server Error'
      end
    end
  end
end

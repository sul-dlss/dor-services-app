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
    build(:dro, id: druid, label: 'A new map of Africa', admin_policy_id: apo_druid).new(identification: identification, description: description)
  end
  let(:updated_cocina_object) do
    build(:dro, id: druid, label: 'A new map of Africa', admin_policy_id: apo_druid).new(
      identification: identification,
      description: {
        title: [{ value: 'Paying for College', status: 'primary' }],
        purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}",
        adminMetadata: {
          note: [
            {
              type: 'record origin',
              value: "Converted from MARCXML to MODS version 3.7 using\n\t\t\t\t" \
                     "MARC21slim2MODS3-7_SDR_v2-6.xsl (SUL 3.7 version 2.6 20220603; LC Revision 1.140\n\t\t\t\t" \
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

  let(:symphony_reader) { instance_double(SymphonyReader, to_marc: marc) }

  before do
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(cocina_apo_object)
    allow(CocinaObjectStore).to receive(:save).and_return(updated_cocina_object)
  end

  context 'when happy path' do
    before do
      allow(SymphonyReader).to receive(:new).and_return(symphony_reader)
    end

    it 'updates the metadata and saves the changes' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(CocinaObjectStore).to have_received(:save).with(updated_cocina_object)
    end
  end

  context 'when the cocina object only has a barcode' do
    let(:identification) do
      {
        barcode: '36105216275185',
        sourceId: 'sul:123'
      }
    end

    before do
      allow(SymphonyReader).to receive(:new).and_return(symphony_reader)
    end

    it 'updates the metadata and saves the changes' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(CocinaObjectStore).to have_received(:save).with(updated_cocina_object)
    end
  end

  context 'with a collection' do
    let(:cocina_object) do
      build(:collection, id: druid)
    end

    before do
      allow(SymphonyReader).to receive(:new).and_return(symphony_reader)
    end

    it 'returns a 422 error' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match("#{druid} had no catkeys marked as refreshable")
    end
  end

  describe 'errors in response from Symphony' do
    let(:marc_url) { Settings.catalog.symphony.base_url + Settings.catalog.symphony.marcxml_path }
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

    context 'when incomplete response' do
      before do
        stub_request(:get, format(marc_url, catkey: '666')).to_return(body: '{}', headers: { 'Content-Length': 0 })
      end

      it 'returns a 500 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to match('Incomplete response received from Symphony for 666 - expected 0 bytes but got 2')
      end
    end

    context 'when catkey not found' do
      before do
        stub_request(:get, format(marc_url, catkey: '666')).to_return(status: 404)
      end

      it 'returns a 400 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json.dig('errors', 0, 'title')).to eq 'Catkey not found in Symphony'
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
        stub_request(:get, format(marc_url, catkey: '666')).to_return(status: 403, body: err_body.to_json)
      end

      it 'returns a 500 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to match(%r{Got HTTP Status-Code 403 calling https://sirsi.example.com/symws/catalog/bib/key/666\?includeFields=bib:.*Something somewhere went wrong.})
      end
    end

    context 'when transform error' do
      let(:xslt) { instance_double(Nokogiri::XSLT::Stylesheet) }

      before do
        allow(SymphonyReader).to receive(:new).and_return(symphony_reader)
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

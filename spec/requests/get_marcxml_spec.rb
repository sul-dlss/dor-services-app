# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Looking up an item's marcxml" do
  let(:barcode_url) { Settings.catalog.symphony.json_url + Settings.catalog.symphony.barcode_path }
  let(:marc_url) { Settings.catalog.symphony.json_url + Settings.catalog.symphony.marcxml_path }
  let(:barcode) { '101' }
  let(:catkey) { '12345' }
  let(:body) do
    {
      resource: '/catalog/bib',
      key: '111',
      fields: {
        bib: {
          standard: 'MARC21',
          type: 'BIB',
          leader: '00956cem 2200229Ma 4500',
          fields: [
            { tag: '001', subfields: [{ code: '_', data: 'some data' }] },
            { tag: '001', subfields: [{ code: '_', data: 'some other data' }] },
            { tag: '009', subfields: [{ code: '_', data: 'whatever' }] },
            {
              tag: '245',
              inds: '41',
              subfields: [{ code: 'a', data: 'some data' }]
            }
          ]
        }
      }
    }
  end
  let(:barcode_body) do
    {
      resource: '/catalog/item',
      key: '2823549:3:2',
      fields:
        {
          shadowed: false,
          permanent: true,
          bib:
           {
             resource: '/catalog/bib',
             key: catkey,
             barcode: barcode
           }
        }
    }
  end

  it 'looks up an item by catkey' do
    stub_request(:get, format(marc_url, catkey: catkey)).to_return(body: body.to_json, headers: { 'Content-Length': 394 })

    get "/v1/catalog/marcxml?catkey=#{catkey}", headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response.body).to start_with '<record'
  end

  it 'looks up an item by barcode' do
    stub_request(:get, format(barcode_url, barcode: barcode)).to_return(body: barcode_body.to_json, headers: { 'Content-Length': 157 })
    stub_request(:get, format(marc_url, catkey: catkey)).to_return(body: body.to_json, headers: { 'Content-Length': 394 })

    get "/v1/catalog/marcxml?barcode=#{barcode}", headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(response.body).to start_with '<record'
  end

  describe 'errors in response from Symphony' do
    context 'when incomplete response' do
      before do
        stub_request(:get, format(marc_url, catkey: catkey)).to_return(body: '{}', headers: { 'Content-Length': 0 })
      end

      it 'returns a 500 error' do
        get "/v1/catalog/marcxml?catkey=#{catkey}", headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(500)
        expect(response.body).to eq("Incomplete response received from Symphony for #{catkey} - expected 0 bytes but got 2")
      end
    end

    context 'when catkey not found' do
      let(:bogus_value) { 'bogus' }

      it 'returns a 500 error when fetching marcxml' do
        stub_request(:get, format(marc_url, catkey: bogus_value)).to_return(status: 404)
        get "/v1/catalog/marcxml?catkey=#{bogus_value}", headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(500)
        expect(response.body).to eq("Record not found in Symphony. API call: https://sirsi.example.com/symws/catalog/bib/key/#{bogus_value}?includeFields=bib")
      end
    end

    context 'when other HTTP error' do
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
        stub_request(:get, format(marc_url, catkey: catkey)).to_return(status: 403, body: err_body.to_json)
      end

      it 'returns a 500 error' do
        get "/v1/catalog/marcxml?catkey=#{catkey}", headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(500)
        expect(response.body).to match(/^Got HTTP Status-Code 403.*:.*Something somewhere went wrong./)
      end
    end
  end
end

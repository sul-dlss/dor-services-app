# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Looking up an item's catkey by it's barcode" do
  let(:barcode_url) { Settings.catalog.symphony.json_url + Settings.catalog.symphony.barcode_path }
  let(:barcode) { '101' }
  let(:barcode_with_no_catkey) { '102' }
  let(:catkey) { '12345' }
  let(:barcode_with_no_catkey_body) do
    {
      resource: '/catalog/item',
      key: '2823549:3:2',
      fields:
        {
          shadowed: false,
          permanent: true
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

  it 'looks up an item by barcode' do
    stub_request(:get, format(barcode_url, barcode: barcode)).to_return(body: barcode_body.to_json, headers: { 'Content-Length': 157 })

    get "/v1/catalog/catkey?barcode=#{barcode}", headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(response.body).to eq catkey
  end

  it 'returns nothing when catkey could not be found in returned response' do
    stub_request(:get, format(barcode_url, barcode: barcode_with_no_catkey)).to_return(body: barcode_with_no_catkey_body.to_json, headers: { 'Content-Length': 93 })

    get "/v1/catalog/catkey?barcode=#{barcode_with_no_catkey}", headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(response.body).to eq ''
  end

  context 'when barcode not found' do
    let(:bogus_value) { 'bogus' }

    it 'returns a 500 error when looking up catkey by barcode' do
      stub_request(:get, format(barcode_url, barcode: bogus_value)).to_return(status: 404)
      get "/v1/catalog/catkey?barcode=#{bogus_value}", headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.status).to eq(500)
      expect(response.body).to eq("Record not found in Symphony. API call: https://sirsi.example.com/symws/catalog/item/barcode/#{bogus_value}")
    end
  end
end

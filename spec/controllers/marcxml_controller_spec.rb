# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarcxmlController do
  before do
    login
  end

  let(:resource) { MarcxmlResource.new(catkey: '12345') }
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

  describe 'GET catkey' do
    it 'returns the provided catkey' do
      get :catkey, params: { catkey: '12345' }
      expect(response.body).to eq '12345'
    end

    it 'looks up an item by barcode' do
      stub_request(:get, format(Settings.catalog.barcode_search_url, barcode: '98765')).to_return(body: { barcode: '98765', id: '12345' }.to_json)
      get :catkey, params: { barcode: '98765' }
      expect(response.body).to eq '12345'
    end
  end

  describe 'GET marcxml' do
    it 'retrieves MARCXML' do
      stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: resource.catkey)).to_return(body: body.to_json, headers: { 'Content-Length': 394 })
      get :marcxml, params: { catkey: '12345' }
      expect(response.body).to start_with '<record'
    end
  end

  describe 'GET mods' do
    it 'transforms the MARCXML into MODS' do
      stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: resource.catkey)).to_return(body: body.to_json, headers: { 'Content-Length': 394 })
      get :mods, params: { catkey: '12345' }
      expect(response.body).to match(/mods/)
    end
  end

  describe 'errors in response from Symphony' do
    context 'when incomplete response' do
      before do
        stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: resource.catkey)).to_return(body: '{}', headers: { 'Content-Length': 0 })
      end

      it 'returns a 500 error' do
        get :marcxml, params: { catkey: '12345' }
        expect(response.status).to eq(500)
        expect(response.body).to eq('Incomplete response received from Symphony for 12345 - expected 0 bytes but got 2')
      end
    end

    context 'when catkey not found' do
      before do
        stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: resource.catkey)).to_return(status: 404)
      end

      it 'returns a 500 error' do
        get :marcxml, params: { catkey: '12345' }
        expect(response.status).to eq(500)
        expect(response.body).to eq('Record not found in Symphony: 12345')
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
        stub_request(:get, format(Settings.catalog.symphony.json_url, catkey: resource.catkey)).to_return(status: 403, body: err_body.to_json)
      end

      it 'returns a 500 error' do
        get :marcxml, params: { catkey: '12345' }
        expect(response.status).to eq(500)
        expect(response.body).to match(/^Got HTTP Status-Code 403 retrieving 12345 from Symphony:.*Something somewhere went wrong./)
      end
    end
  end
end

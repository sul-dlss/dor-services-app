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
    it 'looks up an item by barcode' do
      stub_request(:get, format(Settings.catalog.barcode_search_url, barcode: '98765')).to_return(body: { barcode: '98765', id: '12345' }.to_json)
      get :catkey, params: { barcode: '98765' }
      expect(response.body).to eq '12345'
    end
  end
end

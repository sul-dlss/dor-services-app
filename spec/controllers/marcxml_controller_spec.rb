require 'rails_helper'

RSpec.describe MarcxmlController do
  before do
    login
  end

  let(:resource) { MarcxmlResource.new(catkey: '12345') }

  describe 'GET catkey' do
    it 'returns the provided catkey' do
      get :catkey, params: { catkey: '12345' }
      expect(response.body).to eq '12345'
    end

    it 'looks up an item by barcode' do
      stub_request(:get, Settings.CATALOG.SOLR_URL + 'barcode?wt=json&n=98765').to_return(body: { response: { docs: [{ id: '12345' }] } }.to_json)
      get :catkey, params: { barcode: '98765' }
      expect(response.body).to eq '12345'
    end
  end

  describe 'GET marcxml' do
    it 'retrieves MARCXML' do
      stub_request(:get, Settings.CATALOG.SYMPHONY.JSON_URL % { catkey: resource.catkey }).to_return(body: '{}')

      get :marcxml, params: { catkey: '12345' }
      expect(response.body).to start_with '<record'
    end
  end

  describe 'GET mods' do
    it 'transforms the MARCXML into MODS' do
      stub_request(:get, Settings.CATALOG.SYMPHONY.JSON_URL % { catkey: resource.catkey }).to_return(body: '{}')
      get :mods, params: { catkey: '12345' }
      expect(response.body).to match(/mods/)
    end
  end
end

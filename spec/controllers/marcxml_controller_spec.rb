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
      FakeWeb.register_uri(:get, Settings.CATALOG.SOLR_URL + 'barcode?wt=ruby&n=98765', body: { response: { docs: [{ id: '12345' }] } }.to_json)
      get :catkey, params: { barcode: '98765' }
      expect(response.body).to eq '12345'
    end
  end

  describe 'GET marcxml' do
    it 'retrieves MARCXML' do
      FakeWeb.register_uri(:get, Settings.CATALOG.MARCXML_URL % { catkey: resource.catkey }, body: '<marcxml />')

      get :marcxml, params: { catkey: '12345' }
      expect(response.body).to eq '<marcxml />'
    end
  end

  describe 'GET mods' do
    it 'transforms the MARCXML into MODS' do
      FakeWeb.register_uri(:get, Settings.CATALOG.MARCXML_URL % { catkey: resource.catkey }, body: '<marc:record xmlns="http://www.loc.gov/MARC21/slim" />')

      get :mods, params: { catkey: '12345' }
      expect(response.body).to match(/mods/)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Looking up an item's catkey by it's barcode" do
  before do
    stub_request(:get, format(Settings.catalog.barcode_search_url, barcode: '98765'))
      .to_return(body: { barcode: '98765', id: '12345' }.to_json)
  end

  it 'looks up an item by barcode' do
    get '/v1/catalog/catkey?barcode=98765',
        headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response.body).to eq '12345'
  end
end

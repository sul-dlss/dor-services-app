# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Display metadata' do
  let(:object) { Dor::Item.new(pid: 'druid:1234') }

  before do
    object.descMetadata.title_info.main_title = 'Hello'
    allow(Dor).to receive(:find).and_return(object)
  end

  describe 'dublin core' do
    it 'returns the DC xml' do
      get '/v1/objects/druid:mk420bs7601/metadata/dublin_core',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.body).to include '<dc:title>Hello</dc:title>'
    end
  end

  describe 'mods' do
    it 'returns the source MODS xml' do
      get '/v1/objects/druid:mk420bs7601/metadata/mods',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.body).to be_equivalent_to <<~XML
        <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>Hello</title>
          </titleInfo>
        </mods>
      XML
    end
  end

  describe 'descriptive' do
    it 'returns the public xml' do
      get '/v1/objects/druid:mk420bs7601/metadata/descriptive',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(response.body).to be_equivalent_to <<~XML
        <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>Hello</title>
          </titleInfo>
        </mods>
      XML
    end
  end
end

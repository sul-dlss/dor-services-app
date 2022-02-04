# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update MODS' do
  let(:object) { Dor::Item.new(pid: 'druid:mk420bs7601') }

  before do
    object.descMetadata.title_info.main_title = 'Goodbye'
    allow(Dor).to receive(:find).and_return(object)
    allow(object).to receive(:save!)
  end

  context 'with valid xml' do
    let(:xml) do
      <<~XML
        <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>Hello</title>
          </titleInfo>
        </mods>
      XML
    end

    it 'updates the source MODS xml' do
      put '/v1/objects/druid:mk420bs7601/metadata/mods',
          params: xml,
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:no_content)
      expect(object.descMetadata.title_info.main_title).to eq ['Hello']
    end
  end

  context 'with invalid xml' do
    let(:xml) do
      <<~XML
        <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <narf />
        </mods>
      XML
    end

    it 'returns an error' do
      put '/v1/objects/druid:mk420bs7601/metadata/mods',
          params: xml,
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update MODS' do
  let(:object) do
    Dor::Item.new(pid: 'druid:mk420bs7601',
                  label: 'Hey',
                  source_id: 'foo:bar',
                  admin_policy_object_id: 'druid:dd999df4567')
  end

  let(:xml) do
    <<~XML
      <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        <titleInfo>
          <title>Hello</title>
        </titleInfo>
      </mods>
    XML
  end

  before do
    object.descMetadata.title_info.main_title = 'Goodbye'
    allow(Dor).to receive(:find).and_return(object)
    allow(object).to receive(:save!)
    allow(Notifications::ObjectUpdated).to receive(:publish)
  end

  context 'with valid xml' do
    it 'updates the source MODS xml' do
      put '/v1/objects/druid:mk420bs7601/metadata/mods',
          params: xml,
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:no_content)
      expect(object.descMetadata.title_info.main_title).to eq ['Hello']
      expect(object.descMetadata.title_info.main_title).to eq ['Hello']
      expect(Notifications::ObjectUpdated).to have_received(:publish)
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

  context 'when invalid cocina' do
    before do
      allow(Cocina::Mapper).to receive(:build).and_raise(Cocina::Mapper::UnexpectedBuildError, ' #/components/schemas/DRO missing required parameters')
    end

    it 'returns error' do
      put '/v1/objects/druid:mk420bs7601/metadata/mods',
          params: xml,
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match(/Unexpected Cocina::Mapper.build error/)
      expect(object).not_to have_received(:save!)
    end
  end
end

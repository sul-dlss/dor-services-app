# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update MODS' do
  let(:druid) { 'druid:mk420bs7601' }
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:apo_druid) { 'druid:dd999df4567' }
  let(:description) do
    {
      title: [{ value: 'Dummy Title' }],
      purl: "https://purl.stanford.edu/#{bare_druid}"
    }
  end

  let(:cocina_object) do
    build(:dro, id: druid, admin_policy_id: apo_druid, label: 'A new map of Africa').new(
      description: description,
      identification: { sourceId: 'sul:50807230' }
    )
  end
  let(:cocina_apo_object) { build(:admin_policy, id: apo_druid) }

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
    allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(cocina_apo_object)
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
    allow(CocinaObjectStore).to receive(:save)
  end

  context 'with valid xml' do
    let(:new_cocina_object) do
      build(:dro, id: druid, admin_policy_id: apo_druid, label: 'A new map of Africa', title: 'Hello').new(
        identification: { sourceId: 'sul:50807230' }
      )
    end

    it 'updates the source MODS xml' do
      put '/v1/objects/druid:mk420bs7601/metadata/mods',
          params: xml,
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:no_content)
      expect(CocinaObjectStore).to have_received(:save).with(new_cocina_object)
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

    it 'returns no content' do
      put '/v1/objects/druid:mk420bs7601/metadata/mods',
          params: xml,
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:no_content)
    end
  end
end

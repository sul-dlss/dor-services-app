# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update MODS' do
  let(:druid) { 'druid:mk420bs7601' }
  let(:apo_druid) { 'druid:dd999df4567' }
  let(:description) do
    {
      title: [{ value: 'Dummy Title' }],
      purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
    }
  end
  let(:object) do
    Dor::Item.new(pid: 'druid:mk420bs7601',
                  label: 'Hey',
                  source_id: 'foo:bar',
                  admin_policy_object_id: 'druid:dd999df4567')
  end
  let(:cocina_object) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::Vocab.object,
                            label: 'A new map of Africa',
                            version: 1,
                            description: description,
                            identification: { sourceId: 'sul:50807230' },
                            access: {},
                            administrative: { hasAdminPolicy: apo_druid })
  end
  let(:cocina_apo_object) do
    Cocina::Models::AdminPolicy.new(externalIdentifier: apo_druid,
                                    administrative: {
                                      hasAdminPolicy: 'druid:gg123vx9393',
                                      hasAgreement: 'druid:bb008zm4587'
                                    },
                                    version: 1,
                                    label: 'just an apo',
                                    type: Cocina::Models::Vocab.admin_policy)
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
    allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(cocina_apo_object)
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
    allow(CocinaObjectStore).to receive(:save)
  end

  context 'with valid xml' do
    let(:new_cocina_object) do
      Cocina::Models::DRO.new(externalIdentifier: druid,
                              type: Cocina::Models::Vocab.object,
                              label: 'A new map of Africa',
                              version: 1,
                              description: {
                                title: [{ value: 'Hello' }],
                                purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
                              },
                              identification: { sourceId: 'sul:50807230' },
                              access: {},
                              administrative: { hasAdminPolicy: apo_druid })
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

    it 'saves the original cocina object' do
      put '/v1/objects/druid:mk420bs7601/metadata/mods',
          params: xml,
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to have_http_status(:no_content)
    end
  end
end

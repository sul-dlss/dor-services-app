# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh metadata' do
  let(:druid) { 'druid:bc753qt7345' }
  let(:object) { Dor::Item.new(pid: druid) }
  let(:apo_druid) { 'druid:pp000pp0000' }
  let(:description) do
    {
      title: [{ value: 'However am I going to be' }],
      purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
    }
  end
  let(:identification) do
    {
      catalogLinks: [{
        catalog: 'symphony',
        catalogRecordId: '10121797'
      }]
    }
  end
  let(:cocina_object) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::Vocab.object,
                            label: 'A new map of Africa',
                            version: 1,
                            description: description,
                            identification: identification,
                            access: {},
                            administrative: { hasAdminPolicy: apo_druid })
  end
  let(:updated_cocina_object) do
    Cocina::Models::DRO.new(externalIdentifier: druid,
                            type: Cocina::Models::Vocab.object,
                            label: 'A new map of Africa',
                            version: 1,
                            description: {
                              title: [{ value: 'Paying for College' }],
                              purl: "https://purl.stanford.edu/#{Dor::PidUtils.remove_druid_prefix(druid)}"
                            },
                            identification: identification,
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

  let(:mods) do
    <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.7">
        <titleInfo>
          <title>Paying for College</title>
        </titleInfo>
      </mods>
    XML
  end

  before do
    allow(Dor).to receive(:find).and_return(object)
    allow(CocinaObjectStore).to receive(:find).and_return(cocina_object)
    allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(cocina_apo_object)
    allow(CocinaObjectStore).to receive(:save).and_return(updated_cocina_object)
  end

  context 'when happy path' do
    before do
      allow(MetadataService).to receive(:fetch).and_return(mods)
    end

    it 'updates the metadata and saves the changes' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(CocinaObjectStore).to have_received(:save).with(updated_cocina_object)
    end
  end

  context 'when the cocina object only has a barcode' do
    let(:identification) do
      {
        barcode: '36105216275185'
      }
    end

    before do
      allow(MetadataService).to receive(:fetch).and_return(mods)
    end

    it 'updates the metadata and saves the changes' do
      post '/v1/objects/druid:mk420bs7601/refresh_metadata',
           headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response).to be_successful
      expect(CocinaObjectStore).to have_received(:save).with(updated_cocina_object)
    end
  end

  describe 'errors in response from Symphony' do
    let(:marc_url) { Settings.catalog.symphony.base_url + Settings.catalog.symphony.marcxml_path }
    let(:identification) do
      {
        catalogLinks: [{
          catalog: 'symphony',
          catalogRecordId: '666'
        }]
      }
    end

    context 'when incomplete response' do
      before do
        stub_request(:get, format(marc_url, catkey: '666')).to_return(body: '{}', headers: { 'Content-Length': 0 })
      end

      it 'returns a 500 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(500)
        expect(response.body).to eq('Incomplete response received from Symphony for 666 - expected 0 bytes but got 2')
      end
    end

    context 'when catkey not found' do
      before do
        stub_request(:get, format(marc_url, catkey: '666')).to_return(status: 404)
      end

      it 'returns a mk420bs7601 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json.dig('errors', 0, 'title')).to eq 'Catkey not found in Symphony'
      end
    end

    context 'when HTTP error' do
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
        stub_request(:get, format(marc_url, catkey: '666')).to_return(status: 403, body: err_body.to_json)
      end

      it 'returns a 500 error' do
        post '/v1/objects/druid:mk420bs7601/refresh_metadata',
             headers: { 'Authorization' => "Bearer #{jwt}" }
        expect(response.status).to eq(500)
        expect(response.body).to match(%r{^Got HTTP Status-Code 403 calling https://sirsi.example.com/symws/catalog/bib/key/666\?includeFields=bib:.*Something somewhere went wrong.})
      end
    end
  end
end

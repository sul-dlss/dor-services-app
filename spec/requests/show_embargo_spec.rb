# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show embargo' do
  let(:payload) { { sub: 'argo' } }
  let(:jwt) { JWT.encode(payload, Settings.dor.hmac_secret, 'HS256') }
  let(:item) { Dor::Item.new(pid: 'druid:mk420bs7601') }
  let(:embargoed_item) { Dor::Item.new(pid: 'druid:mk420bs7602') }
  let(:no_embargoDS_item) { Dor::Item.new(pid: 'druid:mk420bs7603') }

  context 'when an non-embargoed item is found' do
    before do
      allow(Dor).to receive(:find).and_return(item)
      embargo_metadata_xml = Dor::EmbargoMetadataDS.new
      allow(embargo_metadata_xml).to receive_messages(ng_xml: Nokogiri::XML('<xml/>'))
      allow(item).to receive_messages(
        id: 'druid:mk420bs7601',
        datastreams: { 'embargoMetadata' => embargo_metadata_xml },
        embargoMetadata: embargo_metadata_xml
      )
    end

    it 'returns HTTP 200 with false embargo status' do
      get '/v1/objects/druid:mk420bs7601/embargo.json',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.body).to eq({ embargoed: false, release_date: nil }.to_json)
      expect(response.status).to eq(200)
    end
  end

  context 'when an embargoed item is found' do
    before do
      allow(Dor).to receive(:find).and_return(embargoed_item)
      embargoed_item_metadata_xml = Dor::EmbargoMetadataDS.new
      embargoed_xml = <<~XML
        <embargoMetadata>
          <status>embargoed</status>
          <releaseDate>2900-09-15T07:00:00Z</releaseDate>
          <twentyPctVisibilityStatus/>
          <twentyPctVisibilityReleaseDate/>
          <releaseAccess>
            <access type="read">
              <machine>
                <world/>
              </machine>
            </access>
          </releaseAccess>
        </embargoMetadata>
      XML
      allow(embargoed_item_metadata_xml).to receive_messages(ng_xml: Nokogiri::XML(embargoed_xml))
      allow(embargoed_item).to receive_messages(
        id: 'druid:mk420bs7602',
        datastreams: { 'embargoMetadata' => embargoed_item_metadata_xml },
        embargoMetadata: embargoed_item_metadata_xml
      )
    end

    it 'returns HTTP 200 with true embargo status and date' do
      get '/v1/objects/druid:mk420bs7602/embargo.json',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.body).to eq({ embargoed: true, release_date: '2900-09-15T07:00:00.000Z' }.to_json)
      expect(response.status).to eq(200)
    end
  end

  context 'when an item with no embargoMetadata is found' do
    before do
      allow(Dor).to receive(:find).and_return(no_embargoDS_item)
      allow(item).to receive_messages(
        id: 'druid:mk420bs7603'
      )
    end

    it 'returns HTTP 200 with false embargo status' do
      get '/v1/objects/druid:mk420bs7603/embargo.json',
          headers: { 'Authorization' => "Bearer #{jwt}" }
      expect(response.body).to eq({ embargoed: false, release_date: nil }.to_json)
      expect(response.status).to eq(200)
    end
  end
end

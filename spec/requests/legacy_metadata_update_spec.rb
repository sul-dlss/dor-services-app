# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update the legacy (datastream) metadata' do
  let(:work) { instance_double(Dor::Item, pid: 'druid:bc123df4567', datastreams: datastreams, save!: nil) }
  let(:create_date) { Time.zone.parse('2019-08-09T19:18:15Z') }
  let(:descMetadata) { instance_double(Dor::DescMetadataDS, createDate: create_date) }
  let(:rightsMetadata) { instance_double(Dor::RightsMetadataDS, createDate: create_date) }
  let(:technicalMetadata) { instance_double(Dor::TechnicalMetadataDS, createDate: create_date) }
  let(:contentMetadata) { instance_double(Dor::ContentMetadataDS, createDate: create_date) }

  let(:datastreams) do
    {
      'descMetadata' => descMetadata,
      'rightsMetadata' => rightsMetadata,
      'technicalMetadata' => technicalMetadata,
      'contentMetadata' => contentMetadata
    }
  end

  context 'when update is successful' do
    before do
      allow(Dor).to receive(:find).and_return(work)
      allow(LegacyMetadataService).to receive(:update_datastream_if_newer)
    end

    let(:data) do
      <<~JSON
        {
          "descriptive": {
            "updated": "2019-11-08T15:15:43Z",
            "content": "<descMetadata></descMetadata>"
          },
          "rights": {
            "updated": "2019-11-08T15:15:43Z",
            "content": "<rightsMetadata></rightsMetadata>"
          }
        }
      JSON
    end

    it 'updates the object datastreams' do
      patch "/v1/objects/#{work.pid}/metadata/legacy",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(response).to have_http_status(:no_content)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: descMetadata,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: '<descMetadata></descMetadata>',
              event_factory: EventFactory)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: rightsMetadata,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: '<rightsMetadata></rightsMetadata>',
              event_factory: EventFactory)

      expect(work).to have_received(:save!)
    end
  end
end

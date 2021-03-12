# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update the legacy (datastream) metadata' do
  let(:work) { instance_double(Dor::Item, pid: 'druid:bc123df4567', datastreams: datastreams, save!: nil) }
  let(:create_date) { Time.zone.parse('2019-08-09T19:18:15Z') }
  let(:administrative) { instance_double(Dor::AdministrativeMetadataDS, createDate: create_date) }
  let(:contentMetadata) { instance_double(Dor::ContentMetadataDS, createDate: create_date) }
  let(:descMetadata) { instance_double(Dor::DescMetadataDS, createDate: create_date) }
  let(:geo_metadata) { instance_double(Dor::GeoMetadataDS, createDate: create_date) }
  let(:identityMetadata) { instance_double(Dor::IdentityMetadataDS, createDate: create_date) }
  let(:provenanceMetadata) { instance_double(Dor::ProvenanceMetadataDS, createDate: create_date) }
  let(:rels_ext) { instance_double(ActiveFedora::RelsExtDatastream, createDate: create_date) }
  let(:rightsMetadata) { instance_double(Dor::RightsMetadataDS, createDate: create_date) }
  let(:technicalMetadata) { instance_double(Dor::TechnicalMetadataDS, createDate: create_date) }
  let(:version_metadata) { instance_double(Dor::VersionMetadataDS, createDate: create_date) }
  let(:rights_xml) do
    <<~XML
      <rightsMetadata>
        <access type="discover">
          <machine>
            <none></none>
          </machine>
        </access>
        <access type="read">
          <machine>
            <none></none>
          </machine>
        </access>
      </rightsMetadata>
    XML
  end

  let(:datastreams) do
    {
      'administrativeMetadata' => administrative,
      'descMetadata' => descMetadata,
      'RELS-EXT' => rels_ext,
      'rightsMetadata' => rightsMetadata,
      'technicalMetadata' => technicalMetadata,
      'contentMetadata' => contentMetadata,
      'provenanceMetadata' => provenanceMetadata,
      'identityMetadata' => identityMetadata,
      'geoMetadata' => geo_metadata,
      'versionMetadata' => version_metadata
    }
  end

  let(:data) do
    <<~JSON
      {
        "administrative": {
          "updated": "2019-11-08T15:15:43Z",
          "content": "<administrativeMetadata></administrativeMetadata>"
        },
        "descriptive": {
          "updated": "2019-11-08T15:15:43Z",
          "content": "<descMetadata></descMetadata>"
        },
        "relationships": {
          "updated": "2019-11-08T15:15:43Z",
          "content": "<relsExt></relsExt>"
        },
        "rights": {
          "updated": "2019-11-08T15:15:43Z",
          "content": #{rights_xml.to_json}
        },
        "identity": {
          "updated": "2019-11-08T15:15:43Z",
          "content": "<identityMetadata></identityMetadata>"
        },
        "provenance": {
          "updated": "2019-11-08T15:15:43Z",
          "content": "<provMetadata></provMetadata>"
        },
        "geo": {
          "updated": "2019-11-08T15:15:43Z",
          "content": "<geoMetadata></geoMetadata>"
        },
        "version": {
          "updated": "2019-11-08T15:15:43Z",
          "content": "<versionMetadata></versionMetadata>"
        }
      }
    JSON
  end

  before do
    allow(Dor).to receive(:find).and_return(work)
    allow(LegacyMetadataService).to receive(:update_datastream_if_newer)
  end

  context 'when update is successful' do
    it 'updates the object datastreams' do
      patch "/v1/objects/#{work.pid}/metadata/legacy",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(response).to have_http_status(:no_content)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: administrative,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: '<administrativeMetadata></administrativeMetadata>',
              event_factory: EventFactory)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: descMetadata,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: '<descMetadata></descMetadata>',
              event_factory: EventFactory)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: rels_ext,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: '<relsExt></relsExt>',
              event_factory: EventFactory)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: rightsMetadata,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: rights_xml,
              event_factory: EventFactory)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: identityMetadata,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: '<identityMetadata></identityMetadata>',
              event_factory: EventFactory)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: provenanceMetadata,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: '<provMetadata></provMetadata>',
              event_factory: EventFactory)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: geo_metadata,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: '<geoMetadata></geoMetadata>',
              event_factory: EventFactory)

      expect(LegacyMetadataService).to have_received(:update_datastream_if_newer)
        .with(datastream: version_metadata,
              updated: Time.zone.parse('2019-11-08T15:15:43Z'),
              content: '<versionMetadata></versionMetadata>',
              event_factory: EventFactory)
      expect(work).to have_received(:save!)
    end
  end

  context 'when fedora failed' do
    before do
      allow(work).to receive(:save!).and_raise(Rubydora::FedoraInvalidRequest)
    end

    it 'updates the object datastreams' do
      patch "/v1/objects/#{work.pid}/metadata/legacy",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to match(/Invalid Fedora request/)
    end
  end

  context 'when rightsMetadata is invalid' do
    let(:rights_xml) do
      '<rightsMetadata></rightsMetadata>'
    end

    it 'returns an error' do
      patch "/v1/objects/#{work.pid}/metadata/legacy",
            params: data,
            headers: { 'Authorization' => "Bearer #{jwt}", 'CONTENT_TYPE' => 'application/json' }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json.dig('errors', 0, 'title')).to eq 'Invalid rightsMetadata'
      expect(json.dig('errors', 0, 'detail')).to eq 'no_discover_access, no_discover_machine, no_read_access, and no_read_machine'
      expect(work).not_to have_received(:save!)
    end
  end
end

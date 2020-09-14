# frozen_string_literal: true

# A controller to display derived metadata about an object
class MetadataController < ApplicationController
  before_action :load_item

  def dublin_core
    service = Publish::DublinCoreService.new(@item)
    render xml: service
  end

  def descriptive
    service = Publish::PublicDescMetadataService.new(@item)
    render xml: service
  end

  # This supports the Legacy Fedora 3 data model. This is used by the accessionWF.
  def update_legacy_metadata
    datastream_names = {
      administrative: 'administrativeMetadata',
      content: 'contentMetadata',
      descriptive: 'descMetadata',
      geo: 'geoMetadata',
      identity: 'identityMetadata',
      provenance: 'provenanceMetadata',
      relationships: 'RELS-EXT',
      rights: 'rightsMetadata',
      technical: 'technicalMetadata',
      version: 'versionMetadata'
    }

    datastream_names.each do |section, datastream_name|
      values = params[section]
      next unless values

      LegacyMetadataService.update_datastream_if_newer(datastream: @item.datastreams[datastream_name],
                                                       updated: Time.zone.parse(values[:updated]),
                                                       content: values[:content],
                                                       event_factory: EventFactory)
    end

    @item.save!
  rescue Rubydora::FedoraInvalidRequest
    render json: { error: 'Invalid Fedora request possibly due to concurrent requests' },
           status: :service_unavailable
  end
end

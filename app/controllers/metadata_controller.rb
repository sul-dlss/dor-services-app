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

  def mods
    render xml: @item.descMetadata.content
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

      validate_rights(values[:content]) if datastream_name == 'rightsMetadata'
      LegacyMetadataService.update_datastream_if_newer(datastream: @item.datastreams[datastream_name],
                                                       updated: Time.zone.parse(values[:updated]),
                                                       content: values[:content],
                                                       event_factory: EventFactory)
    end

    @item.save!
  rescue InvalidRights => e
    render build_error('Invalid rightsMetadata', e)
  rescue Rubydora::FedoraInvalidRequest
    render json: { error: 'Invalid Fedora request possibly due to concurrent requests' },
           status: :service_unavailable
  end

  class InvalidRights < StandardError; end

  private

  # JSON-API error response
  def build_error(msg, err)
    {
      json: {
        errors: [
          {
            status: '422',
            title: msg,
            detail: err.message
          }
        ]
      },
      content_type: 'application/vnd.api+json',
      status: :unprocessable_entity
    }
  end

  def validate_rights(xml)
    dra = Dor::RightsMetadataDS.from_xml(xml).dra_object
    raise InvalidRights, dra.index_elements[:errors].to_sentence if dra.index_elements[:errors].present?
  end
end

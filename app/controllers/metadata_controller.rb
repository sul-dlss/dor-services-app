# frozen_string_literal: true

# A controller to display derived metadata about an object
class MetadataController < ApplicationController
  before_action :load_item, :load_cocina_object
  before_action :load_cocina_object, only: [:public_xml]

  def dublin_core
    desc_md_xml = Publish::PublicDescMetadataService.new(@item).ng_xml(include_access_conditions: false)
    service = Publish::DublinCoreService.new(desc_md_xml)
    render xml: service
  end

  def descriptive
    service = Publish::PublicDescMetadataService.new(@item)
    render xml: service
  end

  def public_xml
    release_tags = ReleaseTags.for(dro_object: @cocina_object)
    service = Publish::PublicXmlService.new(@item, released_for: release_tags, thumbnail_service: ThumbnailService.new(@cocina_object))
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

      LegacyMetadataService.update_datastream_if_newer(item: @item,
                                                       datastream_name: datastream_name,
                                                       updated: Time.zone.parse(values[:updated]),
                                                       content: values[:content],
                                                       event_factory: EventFactory)
    end

    @item.save!
    if Settings.rabbitmq.enabled
      Notifications::ObjectUpdated.publish(model: Cocina::Mapper.build(@item),
                                           created_at: @item.create_date,
                                           modified_at: @item.modified_date)
    end
  rescue LegacyMetadataService::DatastreamValidationError => e
    json_api_error(status: :unprocessable_entity, message: e.detail, title: e.message)
  rescue Rubydora::FedoraInvalidRequest
    json_api_error(status: :service_unavailable, message: 'Invalid Fedora request possibly due to concurrent requests')
  end
end

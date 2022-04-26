# frozen_string_literal: true

# A controller to display derived metadata about an object
class MetadataController < ApplicationController
  before_action :load_cocina_object, only: %i[dublin_core descriptive public_xml]

  def dublin_core
    desc_md_xml = Publish::PublicDescMetadataService.new(@cocina_object).ng_xml(include_access_conditions: false)
    service = Publish::DublinCoreService.new(desc_md_xml)
    render xml: service
  end

  def descriptive
    service = Publish::PublicDescMetadataService.new(@cocina_object)
    render xml: service
  end

  def public_xml
    release_tags = ReleaseTags.for(cocina_object: @cocina_object)
    public_cocina = Publish::PublicCocinaService.create(@cocina_object)
    service = Publish::PublicXmlService.new(public_cocina: public_cocina,
                                            released_for: release_tags,
                                            thumbnail_service: ThumbnailService.new(@cocina_object))
    render xml: service
  end

  DATASTREAM_NAMES = {
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
  }.freeze

  # This supports the Legacy Fedora 3 data model. This is used by the accessionWF.
  def update_legacy_metadata
    item = Dor.find(params[:object_id])
    DATASTREAM_NAMES.each do |section, datastream_name|
      values = params[section]
      next unless values

      LegacyMetadataService.update_datastream_if_newer(item: item,
                                                       datastream_name: datastream_name,
                                                       updated: values[:updated],
                                                       content: values[:content],
                                                       event_factory: EventFactory)
    end

    # Mapping before save to guard against invalid cocina objects.
    cocina_object = Cocina::Mapper.build(item)

    item.save!
    Notifications::ObjectUpdated.publish(model: cocina_object,
                                         created_at: item.create_date,
                                         modified_at: item.modified_date)
  rescue LegacyMetadataService::DatastreamValidationError => e
    json_api_error(status: :unprocessable_entity, message: e.detail, title: e.message)
  rescue Rubydora::FedoraInvalidRequest
    json_api_error(status: :service_unavailable, message: 'Invalid Fedora request possibly due to concurrent requests')
  end
end

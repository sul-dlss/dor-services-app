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
end

# frozen_string_literal: true

# A controller for the MODS data on an object
class ModsController < ApplicationController
  before_action :load_item

  def show
    render xml: @item.descMetadata.content
  end

  def update
    LegacyMetadataService.update_datastream_if_newer(item: @item,
                                                     datastream_name: 'descMetadata',
                                                     updated: Time.zone.now,
                                                     content: request.body.read,
                                                     event_factory: EventFactory)

    # Mapping before save to guard against invalid cocina objects.
    cocina_object = Cocina::Mapper.build(@item)

    @item.save!

    Notifications::ObjectUpdated.publish(model: cocina_object,
                                         created_at: @item.create_date,
                                         modified_at: @item.modified_date)
  rescue LegacyMetadataService::DatastreamValidationError => e
    json_api_error(status: :unprocessable_entity, message: e.detail, title: e.message)
  rescue Rubydora::FedoraInvalidRequest
    json_api_error(status: :service_unavailable, message: 'Invalid Fedora request possibly due to concurrent requests')
  end
end

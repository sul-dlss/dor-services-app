# frozen_string_literal: true

# Adds a constituent relationship between a virtual object and constituent objects
# by taking the following actions:
#  1. altering the structural metadata of the virtual object
#  2. saving the virtual object
class ConstituentService
  VERSION_DESCRIPTION = 'Virtual object created'
  VERSION_SIGNIFICANCE = :major

  # @param [String] virtual_object_druid the identifier of the virtual object
  def initialize(virtual_object_druid:, event_factory:)
    @virtual_object_druid = virtual_object_druid
    @event_factory = event_factory
  end

  # This resets the structural metadata of the virtual object and then adds the constituent resources.
  # Typically this is only called one time (with a list of all the identifiers) because
  # subsequent calls will erase the previous changes.
  # @param [Array<String>] constituent_druids the identifiers of the constituent objects
  # @raise [ItemQueryService::UncombinableItemError] if a constituent object cannot be added to a virtual object
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  # @raise [VersionService::VersioningError] if the object hasn't been opened for versioning, or if accessionWF has
  #   already been instantiated or the current version is missing a tag or description
  # @return [NilClass, Hash] true if successful, hash of errors otherwise (if combinable validation fails)
  def add(constituent_druids:)
    errors = ItemQueryService.validate_combinable_items(virtual_object: virtual_object_druid, constituents: constituent_druids)

    return errors if errors.any?

    # Make sure the virtual object is open before making modifications
    updated_virtual_object = if VersionService.open?(virtual_object)
                               virtual_object
                             else
                               VersionService.open(virtual_object,
                                                   description: VERSION_DESCRIPTION,
                                                   significance: VERSION_SIGNIFICANCE,
                                                   event_factory:)
                             end

    updated_virtual_object = ResetContentMetadataService.reset(cocina_item: updated_virtual_object, constituent_druids:)

    VersionService.close(updated_virtual_object,
                         event_factory:)

    UpdateObjectService.update(updated_virtual_object)

    SynchronousIndexer.reindex_remotely_from_cocina(cocina_object: updated_virtual_object, created_at:, updated_at:)

    publish_constituents!(constituent_druids)

    nil
  end

  private

  attr_reader :virtual_object_druid, :event_factory

  def created_at
    virtual_object.created
  end

  def updated_at
    virtual_object.modified
  end

  def virtual_object
    @virtual_object ||= ItemQueryService.find_combinable_item(virtual_object_druid)
  end

  def publish_constituents!(constituent_druids)
    constituent_druids.each do |constituent_druid|
      cocina_item = CocinaObjectStore.find(constituent_druid)
      Publish::MetadataTransferService.publish(cocina_item)

      next unless cocina_item.identification&.catalogLinks&.any? { |link| link.catalog == 'symphony' }

      UpdateMarcRecordService.update(cocina_item, thumbnail_service: ThumbnailService.new(cocina_item))
    end
  end
end

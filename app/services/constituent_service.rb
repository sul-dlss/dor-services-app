# frozen_string_literal: true

# Adds a constituent relationship between a virtual object and constituent objects
# by taking the following actions:
#  1. altering the structural metadata of the virtual object
#  2. saving the virtual object
class ConstituentService
  VERSION_DESCRIPTION = 'Virtual object created'

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
  #   already been instantiated or the current version is missing a description
  # @return [NilClass, Hash] true if successful, hash of errors otherwise (if combinable validation fails)
  def add(constituent_druids:)
    errors = ItemQueryService.validate_combinable_items(virtual_object: virtual_object_druid, constituents: constituent_druids)

    return errors if errors.any?

    # Make sure the virtual object is open before making modifications
    updated_virtual_object = if WorkflowStateService.open?(druid: virtual_object.externalIdentifier, version: virtual_object.version)
                               virtual_object
                             else
                               VersionService.open(cocina_object: virtual_object,
                                                   description: VERSION_DESCRIPTION,
                                                   event_factory:)
                             end

    updated_virtual_object = ResetContentMetadataService.reset(cocina_item: updated_virtual_object, constituent_druids:)

    UpdateObjectService.update(updated_virtual_object)

    VersionService.close(druid: updated_virtual_object.externalIdentifier, version: updated_virtual_object.version,
                         event_factory:)

    Indexer.reindex(cocina_object: updated_virtual_object)

    publish_constituents!(constituent_druids)

    nil
  end

  private

  attr_reader :virtual_object_druid, :event_factory

  def virtual_object
    @virtual_object ||= ItemQueryService.find_combinable_item(virtual_object_druid)
  end

  def publish_constituents!(constituent_druids)
    constituent_druids.each do |constituent_druid|
      cocina_item = CocinaObjectStore.find(constituent_druid)
      Publish::MetadataTransferService.publish(cocina_item)
    end
  end
end

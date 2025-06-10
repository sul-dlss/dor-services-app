# frozen_string_literal: true

# This handles all of the business logic around updating an object.
# This includes:
#   sending a rabbitMQ notification
#   logging an event
class UpdateObjectService
  def self.update(...)
    new(...).update
  end

  # Normalizes, validates, and updates a Cocina object in the datastore.
  # Since normalization is performed, the Cocina object that is returned may differ from the Cocina object that
  # is provided.
  # @param [Cocina::Models::DRO|Collection|AdminPolicy|DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina_object # rubocop:disable Layout/LineLength
  # @param [boolean] skip_lock do not perform an optimistic lock check
  # @param [boolean] skip_open_check do not check that the object has an open version
  # @param [string] who the sunetid of the user performing the update
  # @param [string] description a description of the update
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore.
  # @raise [StateLockError] raised if optimistic lock failed.
  # @raise [StandardError] raised if the object does not have an open version
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] normalized cocina object
  def initialize(cocina_object:, skip_lock: false, skip_open_check: false, description: nil, who: nil)
    @cocina_object = cocina_object
    @skip_lock = skip_lock
    @skip_open_check = skip_open_check
    @description = description
    @who = who
    @previous_cocina_object = CocinaObjectStore.find(druid) # this is the object about to be updated
  end

  def update # rubocop:disable Metrics/AbcSize
    Cocina::ObjectValidator.validate(cocina_object)
    raise_unless_open_version

    # If this is a collection and the title has changed, then reindex the children.
    update_items = need_to_update_members?

    updated_cocina_object_with_metadata = persist!

    # if the object is a DRO, and the collection has changed, then we need to record a specific event
    send_collection_changed_event if collection_changed?

    EventFactory.create(druid:, event_type: 'update',
                        data: { who:, description:, success: true, request: cocina_object_without_metadata.to_h })

    Indexer.reindex_later(druid:)

    # Update all items in the collection if necessary
    PublishItemsModifiedJob.perform_later(druid) if update_items
    updated_cocina_object_with_metadata
  rescue Cocina::ValidationError => e
    EventFactory.create(druid:, event_type: 'update',
                        data: { who:, description:, success: false, error: e.message,
                                request: cocina_object_without_metadata.to_h })
    raise
  end

  private

  attr_reader :cocina_object, :skip_lock, :skip_open_check, :who, :description, :previous_cocina_object

  delegate :version, to: :cocina_object

  def druid
    cocina_object.externalIdentifier
  end

  def cocina_object_without_metadata
    @cocina_object_without_metadata ||= Cocina::Models.without_metadata(cocina_object)
  end

  def raise_unless_open_version
    return if skip_open_check || VersionService.open?(druid:, version:)

    raise "Updating repository item #{druid} without an open version"
  end

  def need_to_update_members?
    cocina_object.collection? &&
      object_title(druid) != Cocina::Models::Builders::TitleBuilder.build(cocina_object.description.title)
  end

  def collection_changed?
    # ignore for anything except DROs
    return false unless cocina_object.dro?

    # these are arrays of collection druids, convert to set to ignore ordering
    previous_collections.to_set != new_collections.to_set
  end

  def send_collection_changed_event
    # Note for simplicty in the description, this assumes that only one collection was changed
    # and records the first.  This is the most likely scenario, even though, given that
    # an object can be in multiple collections, it is possible for it to be moved from
    # multiple collections to multiple new collections.

    # In theory, these could be nil if we are moving from no collection to a collection
    # or removing from a single collection
    new_collection_druid = (new_collections - previous_collections).first
    previous_collection_druid = (previous_collections - new_collections).first

    collection_changed_description = "Moved from #{object_title(previous_collection_druid)} " \
                                     "(#{previous_collection_druid}) " \
                                     "to #{object_title(new_collection_druid)} (#{new_collection_druid})"

    EventFactory.create(druid:, event_type: 'collection_changed',
                        data: { who:, description: collection_changed_description })
  end

  # array of collections druids the object is currently in
  def previous_collections
    previous_cocina_object.structural.isMemberOf || []
  end

  # array of collection druids the object will be updated to
  def new_collections
    cocina_object.structural.isMemberOf || []
  end

  def object_title(druid)
    return 'None' unless druid

    Cocina::Models::Builders::TitleBuilder.build(CocinaObjectStore.find(druid).description.title)
  end

  def persist! # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    cocina_object_with_metadata = nil
    begin
      RepositoryObject.transaction do
        repo_object = RepositoryObject.find_by!(external_identifier: druid)
        # This checks that the repository object was not modified between when the repository object was
        # retrieved and now.
        repo_object.check_lock!(cocina_object) unless skip_lock
        repo_object.update_opened_version_from(cocina_object: cocina_object_without_metadata)
        cocina_object_with_metadata = repo_object.head_version.to_cocina_with_metadata
      end
    rescue ActiveRecord::RecordNotUnique => e
      message = if e.message.include?('index_repository_objects_on_source_id')
                  source_id = cocina_object.identification.sourceId
                  existing_druid = CocinaObjectStore.find_by_source_id(source_id).externalIdentifier # rubocop:disable Rails/DynamicFindBy
                  "An object (#{existing_druid}) with the source ID '#{source_id}' has already been registered."
                else
                  'ExternalIdentifier or sourceId is not unique.'
                end
      raise Cocina::ValidationError.new(message, status: :conflict)
    end
    cocina_object_with_metadata
  end
end

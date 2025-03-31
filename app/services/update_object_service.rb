# frozen_string_literal: true

# This handles all of the business logic around updating an object.
# This includes:
#   sending a rabbitMQ notification
#   logging an event
class UpdateObjectService
  # Normalizes, validates, and updates a Cocina object in the datastore.
  # Since normalization is performed, the Cocina object that is returned may differ from the Cocina object that
  # is provided.
  # @param [Cocina::Models::DRO|Collection|AdminPolicy|DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina_object # rubocop:disable Layout/LineLength
  # @param [boolean] skip_lock do not perform an optimistic lock check
  # @param [boolean] skip_open_check do not check that the object has an open version
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore.
  # @raise [StateLockError] raised if optimistic lock failed.
  # @raise [StandardError] raised if the object does not have an open version
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] normalized cocina object
  def self.update(cocina_object, skip_lock: false, skip_open_check: false)
    new(cocina_object:, skip_lock:, skip_open_check:).update
  end

  def initialize(cocina_object:, skip_lock:, skip_open_check:)
    @cocina_object = cocina_object
    @skip_lock = skip_lock
    @skip_open_check = skip_open_check
  end

  def update # rubocop:disable Metrics/AbcSize
    Cocina::ObjectValidator.validate(cocina_object)
    raise_unless_open_version

    # If this is a collection and the title has changed, then reindex the children.
    update_items = need_to_update_members?

    updated_cocina_object_with_metadata = persist!

    EventFactory.create(druid:, event_type: 'update',
                        data: { success: true, request: cocina_object_without_metadata.to_h })

    Indexer.reindex_later(cocina_object: updated_cocina_object_with_metadata)

    # Update all items in the collection if necessary
    PublishItemsModifiedJob.perform_later(druid) if update_items
    updated_cocina_object_with_metadata
  rescue Cocina::ValidationError => e
    EventFactory.create(druid:, event_type: 'update',
                        data: { success: false, error: e.message, request: cocina_object_without_metadata.to_h })
    raise
  end

  private

  attr_reader :cocina_object, :skip_lock, :skip_open_check

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
      Cocina::Models::Builders::TitleBuilder.build(CocinaObjectStore.find(druid).description.title) !=
        Cocina::Models::Builders::TitleBuilder.build(cocina_object.description.title)
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

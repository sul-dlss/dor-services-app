# frozen_string_literal: true

# This handles all of the business logic around updating an object.
# This includes:
#   sending a rabbitMQ notification
#   logging an event
class UpdateObjectService
  # Normalizes, validates, and updates a Cocina object in the datastore.
  # Since normalization is performed, the Cocina object that is returned may differ from the Cocina object that is provided.
  # @param [Cocina::Models::DRO|Collection|AdminPolicy|DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina_object
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

  def update
    Cocina::ObjectValidator.validate(cocina_object)
    raise_unless_open_version

    cocina_object_without_metadata = Cocina::Models.without_metadata(cocina_object)

    # If this is a collection and the title has changed, then reindex the children.
    update_items = need_to_update_members?

    cocina_object_with_metadata = persist(cocina_object_without_metadata)

    compare_legacy

    EventFactory.create(druid:, event_type: 'update', data: { success: true, request: cocina_object_without_metadata.to_h })

    Indexer.reindex_later(cocina_object: cocina_object_with_metadata)

    # Update all items in the collection if necessary
    PublishItemsModifiedJob.perform_later(druid) if update_items
    cocina_object_with_metadata
  rescue Cocina::ValidationError => e
    EventFactory.create(druid:, event_type: 'update',
                        data: { success: false, error: e.message, request: Cocina::Models.without_metadata(cocina_object).to_h })
    raise
  end

  private

  attr_reader :cocina_object, :skip_lock, :skip_open_check

  delegate :version, to: :cocina_object

  def druid
    cocina_object.externalIdentifier
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

  def compare_legacy
    RepositoryObject.transaction(isolation: ActiveRecord::Base.connection.transaction_open? ? nil : :read_committed) do
      next unless Settings.enabled_features.repository_object_test

      repo_object = RepositoryObject.find_by(external_identifier: druid)
      next unless repo_object

      cocina = repo_object.head_version.to_cocina
      legacy_cocina_with_metadata = CocinaObjectStore.find(druid)
      legacy_cocina = Cocina::Models.without_metadata(legacy_cocina_with_metadata)
      next if legacy_cocina == cocina

      Honeybadger.notify('Comparison of RepositoryObject with legacy object failed.', context: { legacy: legacy_cocina.to_h, cocina: cocina.to_h })
    end
  end

  def persist(cocina_object_without_metadata)
    cocina_object_with_metadata = nil
    begin
      RepositoryObject.transaction do
        repo_object = RepositoryObject.find_by!(external_identifier: druid)
        repo_object.update_opened_version_from(cocina_object: cocina_object_without_metadata)
        cocina_object_with_metadata = repo_object.head_version.to_cocina_with_metadata

        CocinaObjectStore.store(cocina_object, skip_lock:)
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

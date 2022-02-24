# frozen_string_literal: true

# Abstracts persistence operations for Cocina objects.
# For the actions that are supported, this class includes step that happen regardless of the datastore.
# For example, publishing a notification upon create.
# See ObjectCreator and ObjectUpdater for Fedora-specific steps for creating and updating when persisting to Fedora.
# rubocop:disable Metrics/ClassLength
class CocinaObjectStore
  # Generic base error class.
  class CocinaObjectStoreError < StandardError; end

  # Cocina object not found in datastore.
  class CocinaObjectNotFoundError < CocinaObjectStoreError; end

  # Retrieves a Cocina object from the datastore.
  # @param [String] druid
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object
  # @raise [SolrConnectionError] raised when cannot connect to Solr. This error will no longer be raised when Fedora is removed.
  # @raise [Cocina::Mapper::UnexpectedBuildError] raised when an mapping error occurs. This error will no longer be raised when Fedora is removed.
  # @raise [CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def self.find(druid)
    new.find(druid)
  end

  # Retrieves a Cocina object from the datastore and supplies the timestamps
  # @param [String] druid
  # @return [Array] a tuple consisting of cocina_object, created date and updated date
  # @raise [SolrConnectionError] raised when cannot connect to Solr. This error will no longer be raised when Fedora is removed.
  # @raise [Cocina::Mapper::UnexpectedBuildError] raised when an mapping error occurs. This error will no longer be raised when Fedora is removed.
  # @raise [CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def self.find_with_timestamps(druid)
    new.find_with_timestamps(druid)
  end

  # Determine if an object exists in the datastore.
  # @param [String] druid
  # @return [boolean] true if object exists
  def self.exists?(druid)
    new.exists?(druid)
  end

  # Normalizes, validates, and updates a Cocina object in the datastore.
  # Since normalization is performed, the Cocina object that is returned may differ from the Cocina object that is provided.
  # @param [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object
  # @param [#create] event_factory creates events
  # @raise [Cocina::RoundtripValidationError] raised when validating roundtrip mapping fails. This error will no longer be raised when Fedora is removed.
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore. This error will no longer be raised when support create.
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] normalized cocina object
  def self.save(cocina_object, event_factory: EventFactory)
    new(event_factory: event_factory).save(cocina_object)
  end

  # Removes a Cocina object from the   datastore.
  # @param [String] druid
  # @raise [CocinaObjectNotFoundError] raised when the Cocina object is not found.
  def self.destroy(druid)
    new.destroy(druid)
  end

  # @param [Cocina::Models::DRO] cocina_item
  # @param [Boolean] swallow_exceptions (false) should this return a list even if some members aren't found?
  def self.find_collections_for(cocina_item, swallow_exceptions: false)
    # isMemberOf may be nil, in which case we want to return an empty array
    Array(cocina_item.structural.isMemberOf).filter_map do |collection_id|
      find(collection_id)
    rescue CocinaObjectNotFoundError
      raise unless swallow_exceptions
    end
  end

  # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] cocina_object
  # @param [boolean] assign_doi
  # @param [#create] event_factory creates events
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
  # @raises [SymphonyReader::ResponseError] if symphony connection failed
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  def self.create(cocina_request_object, assign_doi: false, event_factory: EventFactory)
    new(event_factory: event_factory).create(cocina_request_object, assign_doi: assign_doi)
  end

  def initialize(event_factory: EventFactory)
    @event_factory = event_factory
  end

  def find(druid)
    fedora_to_cocina_find(druid).first
  end

  # @return [Array] a tuple consisting of cocina object, created date and modified date
  def find_with_timestamps(druid)
    fedora_to_cocina_find(druid)
  end

  def save(cocina_object)
    validate(cocina_object)
    (fedora_object, created_at, modified_at) = cocina_to_fedora_save(cocina_object)
    add_tags_for_update(cocina_object)

    # Doing late mapping so that can add tags first.
    updated_cocina_object = Cocina::Mapper.build(fedora_object)

    # Only want to update if already exists in PG (i.e., added by create or migration).
    # This will make sure gets correct create/update dates.
    cocina_to_ar_save(updated_cocina_object) if Settings.enabled_features.postgres.update && ar_exists?(cocina_object.externalIdentifier)

    event_factory.create(druid: updated_cocina_object.externalIdentifier, event_type: 'update', data: { success: true, request: updated_cocina_object.to_h })

    # Broadcast this update action to a topic
    Notifications::ObjectUpdated.publish(model: updated_cocina_object, created_at: created_at, modified_at: modified_at)
    updated_cocina_object
  rescue Cocina::ValidationError => e
    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update', data: { success: false, error: e.message, request: cocina_object.to_h })
    raise
  end

  def create(cocina_request_object, assign_doi: false)
    ensure_ur_admin_policy_exists(cocina_request_object)
    validate(cocina_request_object)
    updated_cocina_request_object = merge_access_for(cocina_request_object)
    druid = Dor::SuriService.mint_id

    # This saves the Fedora object.
    fedora_object = fedora_create(updated_cocina_request_object, druid: druid, assign_doi: assign_doi)
    add_tags_for_create(druid, updated_cocina_request_object)
    # This creates version 1.0.0 (Initial Version)
    ObjectVersion.increment_version(druid)

    # Fedora 3 has no unique constrains, so
    # index right away to reduce the likelyhood of duplicate sourceIds
    SynchronousIndexer.reindex_remotely(druid)

    # Doing late mapping so that can add tags first.
    cocina_object = Cocina::Mapper.build(fedora_object)
    cocina_to_ar_save(cocina_object) if Settings.enabled_features.postgres.create

    event_factory.create(druid: druid, event_type: 'registration', data: cocina_object.to_h)

    # Broadcast this to a topic
    Notifications::ObjectCreated.publish(model: cocina_object, created_at: Time.zone.now, modified_at: Time.zone.now)
    cocina_object
  end

  def exists?(druid)
    fedora_exists?(druid)
  end

  # This is only public for migration use.
  def fedora_find(druid)
    item = Dor.find(druid)
    models = ActiveFedora::ContentModel.models_asserted_by(item)
    item = item.adapt_to(Etd) if models.include?('info:fedora/afmodel:Etd')
    item
  rescue ActiveFedora::ObjectNotFoundError
    raise CocinaObjectNotFoundError
  end

  # This is only public for migration use.
  def ar_exists?(druid)
    Dro.exists?(external_identifier: druid) || Collection.exists?(external_identifier: druid) || AdminPolicy.exists?(external_identifier: druid)
  end

  def destroy(druid)
    cocina_object = CocinaObjectStore.find(druid)
    fedora_destroy(druid)

    ar_destroy(druid) if Settings.enabled_features.postgres.destroy && ar_exists?(druid)

    Notifications::ObjectDeleted.publish(model: cocina_object, deleted_at: Time.zone.now)
  end

  private

  attr_reader :event_factory

  # In later steps in the migration, the *fedora* methods will be replaced by the *ar* methods.

  # @return [Array] a tuple consisting of cocina object, created date and modified date
  def fedora_to_cocina_find(druid)
    fedora_object = fedora_find(druid)
    [Cocina::Mapper.build(fedora_object), fedora_object.create_date.to_datetime, fedora_object.modified_date.to_datetime]
  end

  def cocina_to_fedora_save(cocina_object)
    # Currently this only supports an update, not a save.
    fedora_object = fedora_find(cocina_object.externalIdentifier)
    # Updating produces a different Cocina object than it was provided.
    Cocina::ObjectUpdater.run(fedora_object, cocina_object)
    [fedora_object, fedora_object.create_date, fedora_object.modified_date]
  rescue Cocina::Mapper::MapperError, Cocina::ObjectUpdater::NotImplemented => e
    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update', data: { success: false, error: e.message, request: cocina_object.to_h })
    raise
  end

  def fedora_exists?(druid)
    fedora_find(druid)
    true
  rescue CocinaObjectNotFoundError
    false
  end

  def fedora_destroy(druid)
    fedora_find(druid).destroy
  end

  # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] cocina_object
  # @param [String] druid
  # @param [boolean] assign_doi
  # @return [Dor::Abstract] Fedora item
  # @raises SymphonyReader::ResponseError if symphony connection failed
  def fedora_create(cocina_request_object, druid:, assign_doi: false)
    Cocina::ObjectCreator.create(cocina_request_object, druid: druid, assign_doi: assign_doi)
  end

  # The *ar* methods are private. In later steps in the migration, the *ar* methods will be invoked by the
  # above public methods.

  # Persist a Cocina object with ActiveRecord.
  # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
  def cocina_to_ar_save(cocina_object)
    model_clazz = case cocina_object
                  when Cocina::Models::AdminPolicy
                    AdminPolicy
                  when Cocina::Models::DRO
                    Dro
                  when Cocina::Models::Collection
                    Collection
                  else
                    raise CocinaObjectStoreError, "unsupported type #{cocina_object&.type}"
                  end
    model_clazz.upsert_cocina(cocina_object)
    cocina_object
  end

  # Find a Cocina object persisted by ActiveRecord.
  # @param [String] druid to find
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
  def ar_to_cocina_find(druid)
    ar_find(druid).to_cocina
  end

  # Find an ActiveRecord Cocina object.
  # @param [String] druid to find
  # @return [Dro, AdminPolicy, Collection]
  def ar_find(druid)
    ar_cocina_object = Dro.find_by(external_identifier: druid) ||
                       AdminPolicy.find_by(external_identifier: druid) ||
                       Collection.find_by(external_identifier: druid)

    raise CocinaObjectNotFoundError unless ar_cocina_object

    ar_cocina_object
  end

  def ar_destroy(druid)
    ar_find(druid).destroy
  end

  # If an object references the Ur-AdminPolicy, it has to exist first.
  # This is particularly important in testing, where the repository may be empty.
  def ensure_ur_admin_policy_exists(cocina_object)
    return unless Settings.enabled_features.create_ur_admin_policy && cocina_object.administrative.hasAdminPolicy == Settings.ur_admin_policy.druid

    Dor::AdminPolicyObject.exists?(Settings.ur_admin_policy.druid) || UrAdminPolicyFactory.create
  end

  # @raise [Cocina::ValidationError]
  def validate(cocina_object)
    # Validate will raise an error if not valid.
    Cocina::ObjectValidator.validate(cocina_object)
  end

  # Merge the rights, use statement, license and copyright statement from the
  # admin policy to the provided DRO or collection.
  # @return[Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy]
  def merge_access_for(cocina_object)
    return cocina_object if cocina_object.admin_policy?

    apo_object = find(cocina_object.administrative.hasAdminPolicy)
    cocina_object.new(access: AccessMergeService.merge(cocina_object, apo_object))
  end

  def add_tags_for_create(druid, cocina_request_object)
    add_dro_tags_for_create(druid, cocina_request_object) if cocina_request_object.dro?
    add_collection_tags_for_create(druid, cocina_request_object) if cocina_request_object.collection?
  end

  def add_dro_tags_for_create(druid, cocina_request_object)
    tags = []
    process_tag = Cocina::ToFedora::ProcessTag.map(cocina_request_object.type, cocina_request_object.structural&.hasMemberOrders&.first&.viewingDirection)
    tags << process_tag if process_tag
    tags << "Project : #{cocina_request_object.administrative.partOfProject}" if cocina_request_object.administrative.partOfProject
    AdministrativeTags.create(pid: druid, tags: tags) if tags.any?
  end

  def add_collection_tags_for_create(druid, cocina_request_object)
    return unless cocina_request_object.administrative.partOfProject

    AdministrativeTags.create(pid: druid, tags: ["Project : #{cocina_request_object.administrative.partOfProject}"])
  end

  def add_tags_for_update(cocina_object)
    if cocina_object.dro?
      # This is necessary so that the content type tag for a book can get updated
      # to reflect the new direction if the direction hash changed in the structural metadata.
      tag = Cocina::ToFedora::ProcessTag.map(cocina_object.type, cocina_object.structural&.hasMemberOrders&.first&.viewingDirection)
      add_tag_for_update(cocina_object.externalIdentifier, tag, 'Process : Content Type') if tag
    end
    return unless (cocina_object.dro? || cocina_object.collection?) && cocina_object.administrative.partOfProject

    add_tag_for_update(cocina_object.externalIdentifier, "Project : #{cocina_object.administrative.partOfProject}", 'Project')
  end

  def add_tag_for_update(druid, new_tag, prefix)
    raise "Must provide a #{prefix} tag for #{druid}" unless new_tag

    existing_tags = tags_starting_with(druid, prefix)
    if existing_tags.empty?
      AdministrativeTags.create(pid: druid, tags: [new_tag])
    elsif existing_tags.size > 1
      raise "Too many tags for prefix #{prefix}. Expected one."
    elsif existing_tags.first != new_tag
      AdministrativeTags.update(pid: druid, current: existing_tags.first, new: new_tag)
    end
  end

  def tags_starting_with(druid, prefix)
    # This lets us find tags like "Project : Hydrus" when "Project" is the prefix, but will not match on tags like "Project : Hydrus : IR : data"
    prefix_count = prefix.count(':') + 1
    AdministrativeTags.for(pid: druid).select do |tag|
      tag.start_with?(prefix) && tag.count(':') == prefix_count
    end
  end
end
# rubocop:enable Metrics/ClassLength

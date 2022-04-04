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

  # Cocina object in datastore has been updated since this instance was retrieved.
  class StaleLockError < CocinaObjectStoreError; end

  # Retrieves a Cocina object from the datastore.
  # @param [String] druid
  # @return [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata, Cocina::Models::AdminPolicyWithMetadata] cocina_object
  # @raise [SolrConnectionError] raised when cannot connect to Solr. This error will no longer be raised when Fedora is removed.
  # @raise [Cocina::Mapper::UnexpectedBuildError] raised when an mapping error occurs. This error will no longer be raised when Fedora is removed.
  # @raise [CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def self.find(druid)
    new.find(druid)
  end

  # Determine if an object exists in the datastore.
  # @param [String] druid
  # @return [boolean] true if object exists
  def self.exists?(druid)
    new.exists?(druid)
  end

  # Normalizes, validates, and updates a Cocina object in the datastore.
  # Since normalization is performed, the Cocina object that is returned may differ from the Cocina object that is provided.
  # @param [Cocina::Models::DRO|Collection|AdminPolicy|DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina_object
  # @param [#create] event_factory creates events
  # @param [boolean] skip_lock do not perform an optimistic lock check
  # @raise [Cocina::RoundtripValidationError] raised when validating roundtrip mapping fails. This error will no longer be raised when Fedora is removed.
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore.
  # @raise [StateLockError] raised if optimistic lock failed.
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] normalized cocina object
  def self.save(cocina_object, event_factory: EventFactory, skip_lock: false)
    new(event_factory: event_factory).save(cocina_object, skip_lock: skip_lock)
  end

  # Removes a Cocina object from the datastore.
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
  # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata]
  # @raises [SymphonyReader::ResponseError] if symphony connection failed
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  def self.create(cocina_request_object, assign_doi: false, event_factory: EventFactory)
    new(event_factory: event_factory).create(cocina_request_object, assign_doi: assign_doi)
  end

  def initialize(event_factory: EventFactory)
    @event_factory = event_factory
  end

  # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata]
  def find(druid)
    if Settings.enabled_features.postgres && ar_exists?(druid)
      ar_to_cocina_find(druid)
    else
      fedora_to_cocina_find(druid)
    end
  end

  def save(cocina_object, skip_lock: false)
    validate(cocina_object)
    ar_save = Settings.enabled_features.postgres && ar_exists?(cocina_object.externalIdentifier)
    # Skip the lock check for fedora if saving to PG.
    (created_at, modified_at, lock) = cocina_to_fedora_save(cocina_object, skip_lock: skip_lock || ar_save)
    # Only update if already exists in PG (i.e., added by create or migration).
    (created_at, modified_at, lock) = cocina_to_ar_save(cocina_object, skip_lock: skip_lock) if ar_save
    add_tags_for_update(cocina_object)

    cocina_object_without_metadata = Cocina::Models.without_metadata(cocina_object)

    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update', data: { success: true, request: cocina_object_without_metadata.to_h })

    # Broadcast this update action to a topic
    Notifications::ObjectUpdated.publish(model: cocina_object_without_metadata, created_at: created_at, modified_at: modified_at)
    Cocina::Models.with_metadata(cocina_object, lock, created: created_at, modified: modified_at)
  rescue Cocina::ValidationError => e
    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update',
                         data: { success: false, error: e.message, request: Cocina::Models.without_metadata(cocina_object).to_h })
    raise
  end

  def create(cocina_request_object, assign_doi: false)
    ensure_ur_admin_policy_exists(cocina_request_object)
    validate(cocina_request_object)
    updated_cocina_request_object = merge_access_for(cocina_request_object)
    druid = SuriService.mint_id
    updated_cocina_request_object = sync_from_symphony(updated_cocina_request_object, druid)
    updated_cocina_request_object = add_description(updated_cocina_request_object)
    cocina_object = cocina_from_request(updated_cocina_request_object, druid)
    cocina_object = assign_doi(cocina_object) if assign_doi

    # This saves the Fedora object.
    (created_at, modified_at, lock) = fedora_create(cocina_object, druid: druid)
    (created_at, modified_at, lock) = cocina_to_ar_save(cocina_object, skip_lock: true) if Settings.enabled_features.postgres
    add_tags_for_create(druid, cocina_request_object)
    # This creates version 1.0.0 (Initial Version)
    ObjectVersion.increment_version(druid)

    created_at ||= Time.zone.now
    updated_at ||= created_at
    # Fedora 3 has no unique constrains, so
    # index right away to reduce the likelyhood of duplicate sourceIds
    SynchronousIndexer.reindex_remotely_from_cocina(cocina_object: cocina_object, created_at: created_at, updated_at: updated_at)

    event_factory.create(druid: druid, event_type: 'registration', data: cocina_object.to_h)

    # Broadcast this to a topic
    Notifications::ObjectCreated.publish(model: cocina_object, created_at: created_at, modified_at: modified_at)
    Cocina::Models.with_metadata(cocina_object, lock, created: created_at, modified: modified_at)
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
  rescue Rubydora::FedoraInvalidRequest, StandardError => e
    new_message = "Unable to find Fedora object or map to cmodel - is identityMetadata DS empty? #{e.message}"
    raise e.class, new_message, e.backtrace
  end

  # This is only public for migration use.
  def ar_exists?(druid)
    Dro.exists?(external_identifier: druid) || Collection.exists?(external_identifier: druid) || AdminPolicy.exists?(external_identifier: druid)
  end

  def destroy(druid)
    cocina_object = CocinaObjectStore.find(druid)
    fedora_destroy(druid)

    ar_destroy(druid) if Settings.enabled_features.postgres && ar_exists?(druid)

    Notifications::ObjectDeleted.publish(model: cocina_object, deleted_at: Time.zone.now)
  end

  private

  attr_reader :event_factory

  # In later steps in the migration, the *fedora* methods will be replaced by the *ar* methods.

  # @return [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata, Cocina::Models::AdminPolicyWithMetadata] cocina_object
  def fedora_to_cocina_find(druid)
    fedora_object = fedora_find(druid)
    cocina_object = Cocina::Mapper.build(fedora_object)
    Cocina::Models.with_metadata(cocina_object, fedora_lock_for(fedora_object), created: fedora_object.create_date.to_datetime, modified: fedora_object.modified_date.to_datetime)
  end

  def fedora_lock_for(fedora_object)
    ActiveSupport::Digest.hexdigest(fedora_object.pid + fedora_object.modified_date.to_datetime.iso8601)
  end

  # @return [Array] array consisting of created date and modified date
  def cocina_to_fedora_save(cocina_object, skip_lock: false)
    # Currently this only supports an update, not a save.
    fedora_object = fedora_find(cocina_object.externalIdentifier)

    fedora_check_lock(fedora_object, cocina_object) unless skip_lock

    # Updating produces a different Cocina object than it was provided.
    Cocina::ObjectUpdater.run(fedora_object, Cocina::Models.without_metadata(cocina_object))
    [fedora_object.create_date.to_datetime, fedora_object.modified_date.to_datetime, fedora_lock_for(fedora_object)]
  rescue Cocina::Mapper::MapperError => e
    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update',
                         data: { success: false, error: e.message, request: Cocina::Models.without_metadata(cocina_object).to_h })
    raise
  end

  def fedora_check_lock(fedora_object, cocina_object)
    return if cocina_object.respond_to?(:lock) && fedora_lock_for(fedora_object) == cocina_object.lock

    raise StaleLockError, "Expected lock of #{fedora_lock_for(fedora_object)} but received #{cocina_object.lock}."
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

  # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
  # @param [String] druid
  # @return [Array] array consisting of created date, modified date, and lock
  # @raises SymphonyReader::ResponseError if symphony connection failed
  def fedora_create(cocina_object, druid:)
    fedora_object = Cocina::ObjectCreator.create(cocina_object, druid: druid)
    [fedora_object.create_date.to_datetime, fedora_object.modified_date.to_datetime, fedora_lock_for(fedora_object)]
  end

  # The *ar* methods are private. In later steps in the migration, the *ar* methods will be invoked by the
  # above public methods.

  # Persist a Cocina object with ActiveRecord.
  # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
  # @return [Array] array consisting of created date, modified date, and lock
  # @raise [Cocina::ValidationError] if externalIdentifier or sourceId not unique
  def cocina_to_ar_save(cocina_object, skip_lock: false)
    ar_check_lock(cocina_object) unless skip_lock

    model_clazz = case cocina_object
                  when Cocina::Models::AdminPolicy, Cocina::Models::AdminPolicyWithMetadata
                    AdminPolicy
                  when Cocina::Models::DRO, Cocina::Models::DROWithMetadata
                    Dro
                  when Cocina::Models::Collection, Cocina::Models::CollectionWithMetadata
                    Collection
                  else
                    raise CocinaObjectStoreError, "unsupported type #{cocina_object&.type}"
                  end
    ar_cocina_object = model_clazz.upsert_cocina(Cocina::Models.without_metadata(cocina_object))
    [ar_cocina_object.created_at.utc, ar_cocina_object.updated_at.utc, ar_lock_for(ar_cocina_object)]
  rescue ActiveRecord::RecordNotUnique
    raise Cocina::ValidationError.new('ExternalIdentifier or sourceId is not unique.', status: :conflict)
  end

  def ar_check_lock(cocina_object)
    ar_object = Dro.find_by(external_identifier: cocina_object.externalIdentifier) ||
                AdminPolicy.find_by(external_identifier: cocina_object.externalIdentifier) ||
                Collection.find_by(external_identifier: cocina_object.externalIdentifier)
    lock = ar_lock_for(ar_object)
    return if cocina_object.respond_to?(:lock) && lock == cocina_object.lock

    raise StaleLockError, "Expected lock of #{lock} but received #{cocina_object.lock}."
  end

  # Find a Cocina object persisted by ActiveRecord.
  # @param [String] druid to find
  # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata]
  def ar_to_cocina_find(druid)
    ar_cocina_object = ar_find(druid)
    Cocina::Models.with_metadata(ar_cocina_object.to_cocina, ar_lock_for(ar_cocina_object), created: ar_cocina_object.created_at.utc, modified: ar_cocina_object.updated_at.utc)
  end

  def ar_lock_for(ar_cocina_object)
    ActiveSupport::Digest.hexdigest(ar_cocina_object.external_identifier + ar_cocina_object.lock.to_s)
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
    AdministrativeTags.create(identifier: druid, tags: tags) if tags.any?
  end

  def add_collection_tags_for_create(druid, cocina_request_object)
    return unless cocina_request_object.administrative.partOfProject

    AdministrativeTags.create(identifier: druid, tags: ["Project : #{cocina_request_object.administrative.partOfProject}"])
  end

  def add_tags_for_update(cocina_object)
    return unless cocina_object.dro?

    # This is necessary so that the content type tag for a book can get updated
    # to reflect the new direction if the direction hash changed in the structural metadata.
    tag = Cocina::ToFedora::ProcessTag.map(cocina_object.type, cocina_object.structural&.hasMemberOrders&.first&.viewingDirection)
    add_tag_for_update(cocina_object.externalIdentifier, tag, 'Process : Content Type') if tag
  end

  def add_tag_for_update(druid, new_tag, prefix)
    raise "Must provide a #{prefix} tag for #{druid}" unless new_tag

    existing_tags = tags_starting_with(druid, prefix)
    if existing_tags.empty?
      AdministrativeTags.create(identifier: druid, tags: [new_tag])
    elsif existing_tags.size > 1
      raise "Too many tags for prefix #{prefix}. Expected one."
    elsif existing_tags.first != new_tag
      AdministrativeTags.update(identifier: druid, current: existing_tags.first, new: new_tag)
    end
  end

  def tags_starting_with(druid, prefix)
    # This lets us find tags like "Project : Hydrus" when "Project" is the prefix, but will not match on tags like "Project : Hydrus : IR : data"
    prefix_count = prefix.count(':') + 1
    AdministrativeTags.for(identifier: druid).select do |tag|
      tag.start_with?(prefix) && tag.count(':') == prefix_count
    end
  end

  # Synch from symphony if a catkey is present
  def sync_from_symphony(cocina_request_object, druid)
    return cocina_request_object if cocina_request_object.admin_policy?

    catkeys = catkeys_for(cocina_request_object)

    return cocina_request_object if catkeys.blank?

    result = RefreshMetadataAction.run(identifiers: catkeys, cocina_object: cocina_request_object, druid: druid)
    return cocina_request_object if result.failure?

    description_props = result.value!.description_props
    # Remove PURL since this is still a request
    description_props.delete(:purl)
    label = MetadataService.label_from_mods(result.value!.mods_ng_xml)
    cocina_request_object.new(label: label, description: description_props)
  end

  def catkeys_for(cocina_request_object)
    cocina_request_object.identification&.catalogLinks&.filter_map { |clink| "catkey:#{clink.catalogRecordId}" if clink.catalog == 'symphony' }
  end

  # Converts from Cocina::Models::RequestDRO|RequestCollection|RequestAdminPolicy to Cocina::Models::DRO|Collection||AdminPolicy
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def cocina_from_request(cocina_request_object, druid)
    props = cocina_request_object.to_h.with_indifferent_access
    props[:externalIdentifier] = druid

    # Add purl to description
    if props[:description].present?
      purl = Purl.for(druid: druid)
      props[:description][:purl] = purl
      # This replaces the :link: placeholder in the citation with the purl, which we are now able to derive.
      # This is specifically for H2, but could be utilized by any client that provides preferred citation.
      Array(props[:description][:note]).each do |note|
        note[:value] = note[:value].gsub(/:link:/, purl) if note[:type] == 'preferred citation' && note[:value]
      end
    end

    # Add externalIdentifiers to structural
    Array(props.dig(:structural, :contains)).each do |fileset_props|
      fileset_id = fileset_props[:externalIdentifier] || Cocina::IdGenerator.generate_or_existing_fileset_id(druid: druid)
      fileset_props[:externalIdentifier] = fileset_id
      Array(fileset_props.dig(:structural, :contains)).each do |file_props|
        file_id = file_props[:externalIdentifier] || Cocina::IdGenerator.generate_or_existing_file_id(druid: druid, resource_id: fileset_id, file_id: file_props[:filename])
        file_props[:externalIdentifier] = file_id
      end
    end

    # Remove partOfProject
    props[:administrative].delete(:partOfProject) if props[:administrative].present?

    # These are not required in requests
    props[:structural] = {} if cocina_request_object.dro? && props[:structural].nil?
    props[:identification] = {} if cocina_request_object.collection? && props[:identification].nil?

    Cocina::Models.build(props)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def assign_doi(cocina_object)
    return cocina_object unless cocina_object.dro?

    identification = cocina_object.identification || Cocina::Models::Identification.new
    cocina_object.new(identification: identification.new(doi: Doi.for(druid: cocina_object.externalIdentifier)))
  end

  def add_description(cocina_request_object)
    return cocina_request_object if cocina_request_object.description.present?

    cocina_request_object.new(description: { title: [{ value: cocina_request_object.label }] })
  end
end
# rubocop:enable Metrics/ClassLength

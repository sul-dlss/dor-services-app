# frozen_string_literal: true

# Abstracts persistence operations for Cocina objects.
# For the actions that are supported, this class includes step that happen regardless of the datastore.
# For example, publishing a notification upon create.
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
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore.
  # @raise [StateLockError] raised if optimistic lock failed.
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] normalized cocina object
  def self.save(cocina_object, event_factory: EventFactory, skip_lock: false)
    new(event_factory:).save(cocina_object, skip_lock:)
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
    new(event_factory:).create(cocina_request_object, assign_doi:)
  end

  def initialize(event_factory: EventFactory)
    @event_factory = event_factory
  end

  # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata]
  def find(druid)
    ar_to_cocina_find(druid)
  end

  def save(cocina_object, skip_lock: false)
    validate(cocina_object)
    # Only update if already exists in PG (i.e., added by create or migration).
    (created_at, modified_at, lock) = cocina_to_ar_save(cocina_object, skip_lock:)

    cocina_object_without_metadata = Cocina::Models.without_metadata(cocina_object)

    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update', data: { success: true, request: cocina_object_without_metadata.to_h })

    # Broadcast this update action to a topic
    Notifications::ObjectUpdated.publish(model: cocina_object_without_metadata, created_at:, modified_at:)
    Cocina::Models.with_metadata(cocina_object, lock, created: created_at, modified: modified_at)
  rescue Cocina::ValidationError => e
    event_factory.create(druid: cocina_object.externalIdentifier, event_type: 'update',
                         data: { success: false, error: e.message, request: Cocina::Models.without_metadata(cocina_object).to_h })
    raise
  end

  # @raises MarcService::MarcServiceError
  def create(cocina_request_object, assign_doi: false)
    ensure_ur_admin_policy_exists(cocina_request_object)
    validate(cocina_request_object)
    updated_cocina_request_object = merge_access_for(cocina_request_object)
    druid = SuriService.mint_id
    updated_cocina_request_object = sync_from_symphony(updated_cocina_request_object, druid)
    updated_cocina_request_object = add_description(updated_cocina_request_object)
    cocina_object = cocina_from_request(updated_cocina_request_object, druid)
    cocina_object = assign_doi(cocina_object) if assign_doi
    (created_at, modified_at, lock) = cocina_to_ar_save(cocina_object, skip_lock: true)
    add_project_tag(druid, cocina_request_object)
    # This creates version 1.0.0 (Initial Version)
    ObjectVersion.initial_version(druid:)

    event_factory.create(druid:, event_type: 'registration', data: cocina_object.to_h)

    # Broadcast this to a topic
    Notifications::ObjectCreated.publish(model: cocina_object, created_at:, modified_at:)
    Cocina::Models.with_metadata(cocina_object, lock, created: created_at, modified: modified_at)
  end

  def exists?(druid)
    ar_exists?(druid)
  end

  # This is only public for migration use.
  def ar_exists?(druid)
    Dro.exists?(external_identifier: druid) || Collection.exists?(external_identifier: druid) || AdminPolicy.exists?(external_identifier: druid)
  end

  def destroy(druid)
    cocina_object = CocinaObjectStore.find(druid)

    ar_destroy(druid)

    Notifications::ObjectDeleted.publish(model: cocina_object, deleted_at: Time.zone.now)
  end

  private

  attr_reader :event_factory

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
  rescue ActiveRecord::RecordNotUnique => e
    message = if e.message.include?('dro_source_id_idx')
                source_id = cocina_object.identification.sourceId
                druid = Dro.find_by("identification->>'sourceId' = ?", source_id).external_identifier
                "An object (#{druid}) with the source ID '#{cocina_object.identification.sourceId}' has already been registered."
              else
                'ExternalIdentifier or sourceId is not unique.'
              end
    raise Cocina::ValidationError.new(message, status: :conflict)
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
    # This should be opaque, but this makes troubeshooting easier.
    [ar_cocina_object.external_identifier, ar_cocina_object.lock.to_s].join('=')
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

    AdminPolicy.exists?(external_identifier: Settings.ur_admin_policy.druid) || UrAdminPolicyFactory.create
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

  def add_project_tag(druid, cocina_request_object)
    return if cocina_request_object.admin_policy? || !cocina_request_object.administrative.partOfProject

    tags = ["Project : #{cocina_request_object.administrative.partOfProject}"]
    AdministrativeTags.create(identifier: druid, tags:)
  end

  # Synch from symphony if a catkey is present
  # @raises MarcService::MarcServiceError
  def sync_from_symphony(cocina_request_object, druid)
    return cocina_request_object if cocina_request_object.admin_policy?

    catkeys = RefreshMetadataAction.identifiers(cocina_object: cocina_request_object)
    return cocina_request_object if catkeys.blank?

    result = RefreshMetadataAction.run(identifiers: catkeys, cocina_object: cocina_request_object, druid:)
    return cocina_request_object if result.failure?

    description_props = result.value!.description_props
    # Remove PURL since this is still a request
    description_props.delete(:purl)
    label = ModsUtils.label(result.value!.mods_ng_xml)
    cocina_request_object.new(label:, description: description_props)
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
      purl = Purl.for(druid:)
      props[:description][:purl] = purl
      # This replaces the :link: placeholder in the citation with the purl, which we are now able to derive.
      # This is specifically for H2, but could be utilized by any client that provides preferred citation.
      Array(props[:description][:note]).each do |note|
        note[:value] = note[:value].gsub(/:link:/, purl) if note[:type] == 'preferred citation' && note[:value]
      end
    end

    # Add externalIdentifiers to structural
    Array(props.dig(:structural, :contains)).each do |fileset_props|
      fileset_id = fileset_props[:externalIdentifier] || Cocina::IdGenerator.generate_or_existing_fileset_id(druid:)
      fileset_props[:externalIdentifier] = fileset_id
      Array(fileset_props.dig(:structural, :contains)).each do |file_props|
        file_id = file_props[:externalIdentifier] || Cocina::IdGenerator.generate_or_existing_file_id(druid:, resource_id: fileset_id, file_id: file_props[:filename])
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

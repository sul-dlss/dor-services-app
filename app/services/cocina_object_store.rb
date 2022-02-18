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

  # Determine if an object exists in the datastore.
  # @param [String] druid
  # @return [boolean] true if object exists
  def self.exists?(druid)
    new.exists?(druid)
  end

  # Normalizes, validates, and updates a Cocina object in the datastore.
  # Since normalization is performed, the Cocina object that is returned may differ from the Cocina object that is provided.
  # @param [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object
  # @raise [Cocina::RoundtripValidationError] raised when validating roundtrip mapping fails. This error will no longer be raised when Fedora is removed.
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  # @raise [CocinaObjectNotFoundError] raised if the cocina object does not already exist in the datastore. This error will no longer be raised when support create.
  # @return [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] normalized cocina object
  def self.save(cocina_object)
    new.save(cocina_object)
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
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
  # @raises [SymphonyReader::ResponseError] if symphony connection failed
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  def self.create(cocina_request_object, assign_doi: false)
    new.create(cocina_request_object, assign_doi: assign_doi)
  end

  def find(druid)
    fedora_to_cocina_find(druid)
  end

  def save(cocina_object)
    validate(cocina_object)
    (updated_cocina_object, created_at, modified_at) = cocina_to_fedora_save(cocina_object)

    # Only want to update if already exists in PG (i.e., added by create or migration).
    # This will make sure gets correct create/update dates.
    if Settings.enabled_features.postgres.update && ar_exists?(cocina_object.externalIdentifier)
      cocina_to_ar_save(updated_cocina_object)
    end

    # Broadcast this update action to a topic
    Notifications::ObjectUpdated.publish(model: updated_cocina_object, created_at: created_at, modified_at: modified_at)
    updated_cocina_object
  end

  def create(cocina_request_object, assign_doi: false)
    ensure_ur_admin_policy_exists(cocina_request_object)
    validate(cocina_request_object)
    updated_cocina_request_object = default_access_for(cocina_request_object)
    druid = Dor::SuriService.mint_id
    cocina_object = fedora_create(updated_cocina_request_object, druid: druid, assign_doi: assign_doi)

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

  # This is only public for ObjectCreator use.
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

  private

  # In later steps in the migration, the *fedora* methods will be replaced by the *ar* methods.

  def fedora_to_cocina_find(druid)
    fedora_object = fedora_find(druid)
    Cocina::Mapper.build(fedora_object)
  end

  def cocina_to_fedora_save(cocina_object)
    # Currently this only supports an update, not a save.
    fedora_object = fedora_find(cocina_object.externalIdentifier)
    # Updating produces a different Cocina object than it was provided.
    [Cocina::ObjectUpdater.run(fedora_object, cocina_object), fedora_object.create_date, fedora_object.modified_date]
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
  # @rturn [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
  # @raises SymphonyReader::ResponseError if symphony connection failed
  def fedora_create(cocina_request_object, druid:, assign_doi: false)
    Cocina::ObjectCreator.create(cocina_request_object, druid: druid, assign_doi: assign_doi)
  end

  # The *ar* methods are private. In later steps in the migration, the *ar* methods will be invoked by the
  # above public methods.

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
    unless Settings.enabled_features.create_ur_admin_policy && cocina_object.administrative.hasAdminPolicy == Settings.ur_admin_policy.druid
      return
    end

    Dor::AdminPolicyObject.exists?(Settings.ur_admin_policy.druid) || UrAdminPolicyFactory.create
  end

  # @raise [Cocina::ValidationError]
  def validate(cocina_object)
    # Validate will raise an error if not valid.
    Cocina::ObjectValidator.validate(cocina_object)
  end

  # Copy the default rights, use statement and copyright statement from the
  # admin policy to the provided DRO or collection.  If the user provided the access
  # subschema, they may overwrite some of these defaults.
  # @return[Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy]
  def default_access_for(cocina_object)
    return cocina_object if cocina_object.admin_policy?

    apo = find(cocina_object.administrative.hasAdminPolicy)
    return cocina_object unless apo.administrative.respond_to?(:defaultAccess) && apo.administrative.defaultAccess

    default_access = apo.administrative.defaultAccess
    updated_access = if cocina_object.collection?
                       # Collection access only supports dark or world, but default access is more complicated
                       (cocina_object.access || Cocina::Models::CollectionAccess).new(access: default_access.access == 'dark' ? 'dark' : 'world')
                     else
                       (cocina_object.access || Cocina::Models::DROAccess).new(default_access.to_h)
                     end
    cocina_object.new(access: updated_access)
  end
end
# rubocop:enable Metrics/ClassLength

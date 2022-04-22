# frozen_string_literal: true

module Cocina
  # Given a Cocina model, create an ActiveFedora model.
  # This should only contain Fedora-specific actions.
  # Actions that should be performed regardless of datastore should be in CocinaObjectStore.
  class ObjectCreator
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def self.create(cocina_object, druid:, persister: ActiveFedoraPersister, cocina_object_store: CocinaObjectStore.new)
      fedora_object, _cocina_object = new(cocina_object_store: cocina_object_store).create(cocina_object, druid: druid, persister: persister)

      # Return Fedora object so that CocinaObjectStore can perform late mapping.
      fedora_object
    end

    def self.trial_create(cocina_object, notifier:, cocina_object_store:)
      new(cocina_object_store: cocina_object_store).create(cocina_object, druid: cocina_object.externalIdentifier, persister: nil, trial: true, notifier: notifier)
    end

    def initialize(cocina_object_store: CocinaObjectStore.new)
      @cocina_object_store = cocina_object_store
    end

    # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
    # @param [String] druid
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def create(cocina_object, druid:, persister:, trial: false, notifier: nil)
      validate(cocina_object) unless trial

      fedora_object = create_from_model(cocina_object, druid: druid, trial: trial)

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      roundtrip_cocina_object = Mapper.build(fedora_object, notifier: notifier)

      persister.store(fedora_object) unless trial

      [fedora_object, roundtrip_cocina_object]
    end

    private

    attr_reader :cocina_object_store

    # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
    # @param [String] druid
    # @param [Boolean] trial
    # @return [Dor::Abstract] a persisted ActiveFedora model
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def create_from_model(cocina_object, druid:, trial:)
      case cocina_object
      when Cocina::Models::AdminPolicy
        create_apo(cocina_object, druid: druid, trial: trial)
      when Cocina::Models::DRO
        create_dro(cocina_object, druid: druid, trial: trial)
      when Cocina::Models::Collection
        create_collection(cocina_object, druid: druid, trial: trial)
      else
        raise "unsupported type #{cocina_object.type}"
      end
    end

    # @param [Cocina::Models::AdminPolicy] cocina_admin_policy
    # @param [String] druid
    # @return [Dor::AdminPolicyObject] a persisted APO model
    def create_apo(cocina_admin_policy, druid:, trial:)
      Dor::AdminPolicyObject.new(pid: druid,
                                 admin_policy_object_id: cocina_admin_policy.administrative.hasAdminPolicy,
                                 agreement_object_id: cocina_admin_policy.administrative.hasAgreement,
                                 # source_id: cocina_admin_policy.identification.sourceId,
                                 label: cocina_admin_policy.label).tap do |fedora_apo|
        add_description(fedora_apo, cocina_admin_policy, trial: trial)

        Cocina::ToFedora::DefaultRights.write(fedora_apo.defaultObjectRights, cocina_admin_policy.administrative.accessTemplate) if cocina_admin_policy.administrative.accessTemplate
        Cocina::ToFedora::AdministrativeMetadata.write(fedora_apo.administrativeMetadata, cocina_admin_policy.administrative)
        Cocina::ToFedora::Roles.write(fedora_apo, Array(cocina_admin_policy.administrative.roles))
        Cocina::ToFedora::Identity.initialize_identity(fedora_apo)
      end
    end

    # @param [Cocina::Models::DRO] cocina_item
    # @param [String] druid
    # @param [Boolean] trial
    # @return [Dor::Item] a persisted Item model
    # @raises SymphonyReader::ResponseError if symphony connection failed
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def create_dro(cocina_item, druid:, trial:)
      klass = cocina_item.type == Cocina::Models::ObjectType.agreement ? Dor::Agreement : Dor::Item
      klass.new(pid: druid,
                admin_policy_object_id: cocina_item.administrative.hasAdminPolicy,
                source_id: cocina_item.identification.sourceId,
                collection_ids: Array.wrap(cocina_item.structural&.isMemberOf).compact,
                catkey: catkey_for(cocina_item)).tap do |fedora_item|
        add_description(fedora_item, cocina_item, trial: trial)

        Cocina::ToFedora::DROAccess.apply(fedora_item, cocina_item.access, cocina_item.structural) if cocina_item.access || cocina_item.structural

        fedora_item.contentMetadata.content = Cocina::ToFedora::ContentMetadataGenerator.generate(druid: druid, type: cocina_item.type, structural: cocina_item.structural,
                                                                                                  cocina_object_store: cocina_object_store)
        identity = Cocina::ToFedora::Identity.new(fedora_item)
        identity.initialize_identity
        identity.apply_release_tags(cocina_item.administrative&.releaseTags)
        identity.apply_doi(cocina_item.identification.doi) if cocina_item.identification&.doi
        identity.apply_catalog_links(cocina_item.identification&.catalogLinks)

        fedora_item.identityMetadata.barcode = cocina_item.identification.barcode if cocina_item.identification.barcode
        fedora_item.geoMetadata.content = cocina_item.geographic.iso19139 if cocina_item&.geographic&.iso19139
      end
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # @param [Cocina::Models::Collection] cocina_collection
    # @param [String] druid
    # @param [Boolean] trial
    # @return [Dor::Collection] a persisted Collection model
    def create_collection(cocina_collection, druid:, trial:)
      Dor::Collection.new(pid: druid,
                          admin_policy_object_id: cocina_collection.administrative.hasAdminPolicy,
                          source_id: cocina_collection.identification&.sourceId,
                          catkey: catkey_for(cocina_collection)).tap do |fedora_collection|
        add_description(fedora_collection, cocina_collection, trial: trial)
        Cocina::ToFedora::CollectionAccess.apply(fedora_collection, cocina_collection.access) if cocina_collection.access
        Cocina::ToFedora::Identity.initialize_identity(fedora_collection)
        Cocina::ToFedora::Identity.apply_catalog_links(fedora_collection, catalog_links: cocina_collection.identification&.catalogLinks)
        Cocina::ToFedora::Identity.apply_release_tags(fedora_collection, release_tags: cocina_collection.administrative&.releaseTags)
      end
    end

    def catkey_for(obj)
      obj.identification&.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

    # @param [Dor::[Item|Collection|APO]] fedora_object
    # @param [Cocina:Models::[DRO|Collection|xxx]] cocina_object
    # @param [Boolean] trial
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def add_description(fedora_object, cocina_object, trial:)
      if cocina_object.description
        fedora_object.descMetadata.content = Cocina::Models::Mapping::ToMods::Description.transform(cocina_object.description, fedora_object.pid).to_xml
        fedora_object.descMetadata.content_will_change!
      end
      Cocina::ToFedora::Identity.apply_label(fedora_object, label: cocina_object.label)
    end

    def validate(cocina_object)
      return unless Settings.enabled_features.validate_descriptive_roundtrip.create

      result = DescriptionRoundtripValidator.valid_from_cocina?(cocina_object)
      raise RoundtripValidationError, result.failure unless result.success?
    end
  end
end

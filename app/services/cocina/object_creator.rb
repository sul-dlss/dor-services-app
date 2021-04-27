# frozen_string_literal: true

module Cocina
  # Given a Cocina model, create an ActiveFedora model.
  class ObjectCreator
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def self.create(cocina_object, event_factory: EventFactory, persister: ActiveFedoraPersister)
      new.create(cocina_object, event_factory: event_factory, persister: persister)
    end

    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] cocina_object
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def create(cocina_object, event_factory:, persister:)
      ensure_ur_admin_policy_exists if Settings.enabled_features.create_ur_admin_policy && cocina_object.administrative.hasAdminPolicy == Settings.ur_admin_policy.druid

      validate(cocina_object)

      af_model = create_from_model(cocina_object, persister: persister)
      # Fedora 3 has no unique constrains, so
      # index right away to reduce the likelyhood of duplicate sourceIds
      SynchronousIndexer.reindex_remotely(af_model.pid)

      event_factory.create(druid: af_model.pid, event_type: 'registration', data: cocina_object.to_h)

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      Mapper.build(af_model)
    end

    private

    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] cocina_object
    # @param [#store] persister the service responsible for persisting the model
    # @return [Dor::Abstract] a persisted ActiveFedora model
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def create_from_model(cocina_object, persister:)
      af_object = case cocina_object
                  when Cocina::Models::RequestAdminPolicy
                    create_apo(cocina_object)
                  when Cocina::Models::RequestDRO
                    create_dro(cocina_object)
                  when Cocina::Models::RequestCollection
                    create_collection(cocina_object)
                  else
                    raise "unsupported type #{cocina_object.type}"
                  end

      persister.store(af_object)
      af_object
    end

    # If an object references the Ur-AdminPolicy, it has to exist first.
    # This is particularly important in testing, where the repository may be empty.
    def ensure_ur_admin_policy_exists
      Dor::AdminPolicyObject.exists?(Settings.ur_admin_policy.druid) || UrAdminPolicyFactory.create
    end

    # @param [Cocina::Models::RequestAdminPolicy] cocina_admin_policy
    # @return [Dor::AdminPolicyObject] a persisted APO model
    def create_apo(cocina_admin_policy)
      pid = Dor::SuriService.mint_id
      Dor::AdminPolicyObject.new(pid: pid,
                                 admin_policy_object_id: cocina_admin_policy.administrative.hasAdminPolicy,
                                 agreement_object_id: cocina_admin_policy.administrative.referencesAgreement,
                                 # source_id: cocina_admin_policy.identification.sourceId,
                                 label: cocina_admin_policy.label).tap do |fedora_apo|
        add_description(fedora_apo, cocina_admin_policy)

        Cocina::ToFedora::DefaultRights.write(fedora_apo.defaultObjectRights, cocina_admin_policy.administrative.defaultAccess) if cocina_admin_policy.administrative.defaultAccess
        Cocina::ToFedora::AdministrativeMetadata.write(fedora_apo.administrativeMetadata, cocina_admin_policy.administrative)
        Cocina::ToFedora::Roles.write(fedora_apo, Array(cocina_admin_policy.administrative.roles))
        Cocina::ToFedora::Identity.apply(fedora_apo, label: cocina_admin_policy.label)
      end
    end

    # @param [Cocina::Models::RequestDRO] cocina_item
    # @return [Dor::Item] a persisted Item model
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def create_dro(cocina_item)
      pid = Dor::SuriService.mint_id
      klass = cocina_item.type == Cocina::Models::Vocab.agreement ? Dor::Agreement : Dor::Item
      klass.new(pid: pid,
                admin_policy_object_id: cocina_item.administrative.hasAdminPolicy,
                source_id: cocina_item.identification.sourceId,
                collection_ids: Array.wrap(cocina_item.structural&.isMemberOf).compact,
                catkey: catkey_for(cocina_item),
                label: truncate_label(cocina_item.label)).tap do |fedora_item|
        add_description(fedora_item, cocina_item)
        add_dro_tags(pid, cocina_item)

        apply_default_access(fedora_item)
        Cocina::ToFedora::DROAccess.apply(fedora_item, cocina_item.access, cocina_item.structural) if cocina_item.access || cocina_item.structural

        fedora_item.contentMetadata.content = Cocina::ToFedora::ContentMetadataGenerator.generate(druid: pid, object: cocina_item)
        Cocina::ToFedora::Identity.apply(fedora_item, label: cocina_item.label, agreement_id: cocina_item.structural&.hasAgreement)

        fedora_item.identityMetadata.barcode = cocina_item.identification.barcode if cocina_item.identification.barcode
      end
    end

    # @param [Cocina::Models::RequestCollection] cocina_collection
    # @return [Dor::Collection] a persisted Collection model
    def create_collection(cocina_collection)
      pid = Dor::SuriService.mint_id
      Dor::Collection.new(pid: pid,
                          admin_policy_object_id: cocina_collection.administrative.hasAdminPolicy,
                          source_id: cocina_collection.identification&.sourceId,
                          catkey: catkey_for(cocina_collection),
                          label: truncate_label(cocina_collection.label)).tap do |fedora_collection|
        add_description(fedora_collection, cocina_collection)
        add_collection_tags(pid, cocina_collection)
        apply_default_access(fedora_collection)
        Cocina::ToFedora::CollectionAccess.apply(fedora_collection, cocina_collection.access) if cocina_collection.access
        Cocina::ToFedora::Identity.apply(fedora_collection, label: cocina_collection.label)
      end
    end

    def catkey_for(obj)
      obj.identification&.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

    # @param [Dor::[Item|Collection|APO]] fedora_object
    # @param [Cocina:Models::Request[DOR|Collection|xxx]] cocina_object
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def add_description(fedora_object, cocina_object)
      # Hydrus doesn't set description. See https://github.com/sul-dlss/hydrus/issues/421
      return if cocina_object.label == 'Hydrus'

      # Synch from symphony if a catkey is present
      if fedora_object.catkey
        RefreshMetadataAction.run(identifiers: ["catkey:#{fedora_object.catkey}"], fedora_object: fedora_object)
        label = MetadataService.label_from_mods(fedora_object.descMetadata.ng_xml)
        fedora_object.label = truncate_label(label)
        fedora_object.objectLabel = label
      elsif cocina_object.description
        description = AddPurlToDescription.call(cocina_object.description, fedora_object.pid)
        fedora_object.descMetadata.content = Cocina::ToFedora::Descriptive.transform(description, fedora_object.pid).to_xml
        fedora_object.descMetadata.content_will_change!
      else
        fedora_object.descMetadata.mods_title = cocina_object.label
      end
    end

    def add_dro_tags(pid, cocina_object)
      tags = []
      process_tag = ToFedora::ProcessTag.map(cocina_object.type, cocina_object.structural&.hasMemberOrders&.first&.viewingDirection)
      tags << process_tag if process_tag
      tags << "Project : #{cocina_object.administrative.partOfProject}" if cocina_object.administrative.partOfProject
      AdministrativeTags.create(pid: pid, tags: tags) if tags.any?
    end

    def add_collection_tags(pid, cocina_object)
      return unless cocina_object.administrative.partOfProject

      AdministrativeTags.create(pid: pid, tags: ["Project : #{cocina_object.administrative.partOfProject}"])
    end

    # Copy the default rights, use statement and copyright statement from the
    # admin policy to the provided item.  If the user provided the access
    # subschema, they may overwrite some of these defaults.
    def apply_default_access(fedora_object)
      apo = Dor.find(fedora_object.admin_policy_object_id)
      rights_xml = apo.defaultObjectRights.ng_xml
      fedora_object.rightsMetadata.content = rights_xml.to_s
    end

    def truncate_label(label)
      label.length > 254 ? label[0, 254] : label
    end

    def validate(cocina_object)
      if Settings.enabled_features.validate_descriptive_roundtrip.create
        result = DescriptionRoundtripValidator.valid_from_cocina?(cocina_object)
        raise RoundtripValidationError, result.failure unless result.success?
      end

      # Validate will raise an error if not valid.
      ObjectValidator.validate(cocina_object)
    end
  end
end

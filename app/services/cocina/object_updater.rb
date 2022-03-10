# frozen_string_literal: true

module Cocina
  # This takes a cocina object and updates the corresponding ActiveFedora object with the provided values
  # This should only contain Fedora-specific actions.
  # Actions that should be performed regardless of datastore should be in CocinaObjectStore.
  class ObjectUpdater
    # @param [ActiveFedora::Base] fedora_object the Fedora object to update
    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] cocina_object the cocina model provided by the client
    # @param [boolean] trial do not persist or event; run all mappings regardless of changes
    # @param [Cocina::FromFedora::DataErrorNotifier] notifier
    # @param [CocinaObjectStore] cocina_object_store
    def self.run(fedora_object, cocina_object, trial: false, notifier: nil, cocina_object_store: CocinaObjectStore)
      new(fedora_object, cocina_object, trial: trial, cocina_object_store: cocina_object_store).run(notifier: notifier)
    end

    def initialize(fedora_object, cocina_object, cocina_object_store:, trial: false)
      @params = params
      @cocina_object = cocina_object
      @fedora_object = fedora_object
      @trial = trial
      @cocina_object_store = cocina_object_store
    end

    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    def run(notifier: nil)
      @notifier = notifier

      # Validate will raise an error if not valid.
      validate unless trial

      case cocina_object
      when Cocina::Models::AdminPolicy
        update_apo
      when Cocina::Models::DRO
        update_dro
      when Cocina::Models::Collection
        update_collection
      else
        raise "unsupported type #{cocina_object.type}"
      end

      update_descriptive if has_changed?(:description)
      update_version if has_changed?(:version)

      # Map back before saving to make sure that valid
      Mapper.build(fedora_object, notifier: notifier)
      fedora_object.save! unless trial
    end

    private

    attr_reader :cocina_object, :fedora_object, :params, :notifier, :trial, :cocina_object_store

    def has_changed?(key)
      return true if trial

      # Update only if changed.
      cocina_object.public_send(key) != orig_cocina_object.public_send(key)
    end

    def orig_cocina_object
      @orig_cocina_object ||= Mapper.build(fedora_object, notifier: notifier)
    end

    # rubocop:disable Style/GuardClause
    def update_apo
      # fedora_object.source_id = cocina_object.identification.sourceId
      Cocina::ToFedora::Identity.apply_label(fedora_object, label: cocina_object.label) if has_changed?(:label)

      if has_changed?(:administrative)
        fedora_object.admin_policy_object_id = cocina_object.administrative.hasAdminPolicy
        fedora_object.agreement_object_id = cocina_object.administrative.hasAgreement

        Cocina::ToFedora::DefaultRights.write(fedora_object.defaultObjectRights, cocina_object.administrative.accessTemplate) if cocina_object.administrative.accessTemplate
        Cocina::ToFedora::AdministrativeMetadata.write(fedora_object.administrativeMetadata, cocina_object.administrative)
        Cocina::ToFedora::Roles.write(fedora_object, Array(cocina_object.administrative.roles))
      end
    end

    # rubocop:enable Style/GuardClause
    def update_collection
      Cocina::ToFedora::Identity.apply_label(fedora_object, label: cocina_object.label) if has_changed?(:label)

      if has_changed?(:administrative)
        Cocina::ToFedora::Identity.apply_release_tags(fedora_object, release_tags: cocina_object.administrative&.releaseTags)
        fedora_object.admin_policy_object_id = cocina_object.administrative.hasAdminPolicy
      end

      Cocina::ToFedora::Identity.apply_catalog_links(fedora_object, catalog_links: cocina_object.identification&.catalogLinks) if has_changed?(:identification)

      fedora_object.catkey = catkey_for(cocina_object)
      Cocina::ToFedora::CollectionAccess.apply(fedora_object, cocina_object.access) if has_changed?(:access)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def update_dro
      fedora_object.admin_policy_object_id = cocina_object.administrative.hasAdminPolicy if has_changed?(:administrative)
      fedora_object.collection_ids = Array.wrap(cocina_object.structural&.isMemberOf).compact if has_changed?(:structural)

      Cocina::ToFedora::Identity.apply_label(fedora_object, label: cocina_object.label) if has_changed?(:label)

      identity_updater = Cocina::ToFedora::Identity.new(fedora_object)
      if has_changed?(:identification)
        identity_updater.apply_doi(cocina_object.identification.doi)
        fedora_object.source_id = cocina_object.identification.sourceId
        fedora_object.catkey = catkey_for(cocina_object)
        identity_updater.apply_catalog_links(cocina_object.identification.catalogLinks)
        fedora_object.identityMetadata.barcode = cocina_object.identification.barcode
      end

      identity_updater.apply_release_tags(cocina_object.administrative&.releaseTags) if has_changed?(:administrative)

      Cocina::ToFedora::DROAccess.apply(fedora_object, cocina_object.access, cocina_object.structural) if has_changed?(:access) || has_changed?(:structural)
      update_content_metadata(fedora_object, cocina_object) if has_changed?(:structural) || has_changed?(:type)

      fedora_object.geoMetadata.content = cocina_object.geographic.iso19139 if cocina_object&.geographic&.iso19139 && has_changed?(:geographic)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def update_content_metadata(fedora_object, cocina_object)
      # We don't want to overwrite contentMetadata unless they provided
      # structural.contains (garden-variety DRO) or structural.hasMemberOrders
      # (virtual object DRO)
      #
      # Note that a change to a book content type will generate completely new
      # structural metadata, and thus lead to a full replacement of the
      # contentMetadata with the new bookData node.
      if cocina_object.structural&.contains.present? || cocina_object.structural&.hasMemberOrders&.first&.members&.present?
        fedora_object.contentMetadata.content = Cocina::ToFedora::ContentMetadataGenerator.generate(
          druid: cocina_object.externalIdentifier,
          type: cocina_object.type,
          structural: cocina_object.structural,
          cocina_object_store: cocina_object_store
        )
      else
        # remove bookData reading order node if no reading direction is specified in the cocina model
        # ...this can happen if the content type is changed from a book type to a non-book type
        fedora_object.contentMetadata.ng_xml.xpath('//bookData').each(&:remove) unless cocina_object.structural&.hasMemberOrders
        fedora_object.contentMetadata.contentType = ToFedora::ContentType.map(cocina_object.type)
      end
    end

    def update_descriptive
      fedora_object.descMetadata.content = Cocina::ToFedora::Descriptive.transform(cocina_object.description, fedora_object.pid).to_xml
      fedora_object.descMetadata.content_will_change!
    end

    # rubocop:disable Style/GuardClause
    def validate
      raise ValidationError, "Identifier on the query and in the body don't match" if fedora_object.pid != cocina_object.externalIdentifier

      if has_changed?(:description) && Settings.enabled_features.validate_descriptive_roundtrip.update
        result = DescriptionRoundtripValidator.valid_from_cocina?(cocina_object)
        raise RoundtripValidationError, result.failure unless result.success?
      end
    end
    # rubocop:enable Style/GuardClause

    def client_attempted_metadata_update?
      title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: fedora_object.label)

      descriptive = FromFedora::Descriptive.props(title_builder: title_builder, mods: fedora_object.descMetadata.ng_xml, druid: fedora_object.pid)
      cocina_object.description.title != descriptive.fetch(:title).map { |value| Cocina::Models::Title.new(value) }
    end

    # TODO: duplicate from ObjectCreator
    def catkey_for(cocina_object)
      cocina_object.identification&.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

    def update_version
      return if version_match?

      fedora_object.versionMetadata.increment_version

      raise "Incremented version of #{fedora_object.current_version} is not expected version #{cocina_object.version}" unless version_match?
    end

    def version_match?
      cocina_object.version.to_s == fedora_object.current_version
    end
  end
end

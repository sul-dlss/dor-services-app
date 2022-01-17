# frozen_string_literal: true

module Cocina
  # This takes a cocina object and updates the corresponding ActiveFedora object
  # with the provided values
  class ObjectUpdater
    class NotImplemented < StandardError; end

    # @param [ActiveFedora::Base] fedora_object the Fedora object to update
    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] cocina_object the cocina model provided by the client
    # @param [#create] event_factory creates events
    # @param [boolean] trial do not persist or event; run all mappings regardless of changes
    # @param [Cocina::FromFedora::DataErrorNotifier] notifier
    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    def self.run(fedora_object, cocina_object, event_factory: EventFactory, trial: false, notifier: nil)
      new(fedora_object, cocina_object, trial: trial).run(event_factory: event_factory, notifier: notifier)
    end

    def initialize(fedora_object, cocina_object, trial: false)
      @params = params
      @cocina_object = cocina_object
      @fedora_object = fedora_object
      @trial = trial
    end

    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    def run(event_factory:, notifier: nil)
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

      update_descriptive if has_changed?(:description) && update_descriptive?

      fedora_object.save! unless trial

      event_factory.create(druid: fedora_object.pid, event_type: 'update_complete', data: { success: true }) unless trial

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      Mapper.build(fedora_object, notifier: notifier).tap do
        event_factory.create(druid: fedora_object.pid, event_type: 'update', data: { success: true, request: cocina_object.to_h }) unless trial
      end
    rescue Mapper::MapperError, ValidationError, NotImplemented => e
      event_factory.create(druid: fedora_object.pid, event_type: 'update', data: { success: false, error: e.message, request: cocina_object.to_h }) unless trial
      raise
    end

    private

    attr_reader :cocina_object, :fedora_object, :params, :notifier, :trial

    def has_changed?(key)
      return true if trial

      # Update only if changed.
      cocina_object.public_send(key) != orig_cocina_object.public_send(key)
    end

    def orig_cocina_object
      @orig_cocina_object ||= Mapper.build(fedora_object, notifier: notifier)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Style/GuardClause
    def update_apo
      # fedora_object.source_id = cocina_object.identification.sourceId
      if has_changed?(:label)
        Cocina::ToFedora::Identity.apply_label(fedora_object, label: cocina_object.label)
        fedora_object.label = truncate_label(cocina_object.label)
      end

      if has_changed?(:administrative)
        fedora_object.admin_policy_object_id = cocina_object.administrative.hasAdminPolicy
        fedora_object.agreement_object_id = cocina_object.administrative.referencesAgreement

        Cocina::ToFedora::DefaultRights.write(fedora_object.defaultObjectRights, cocina_object.administrative.defaultAccess) if cocina_object.administrative.defaultAccess
        Cocina::ToFedora::AdministrativeMetadata.write(fedora_object.administrativeMetadata, cocina_object.administrative)
        Cocina::ToFedora::Roles.write(fedora_object, Array(cocina_object.administrative.roles))
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Style/GuardClause

    def update_collection
      if has_changed?(:label)
        fedora_object.label = truncate_label(cocina_object.label) if has_changed?(:label)
        Cocina::ToFedora::Identity.apply_label(fedora_object, label: cocina_object.label)
      end

      Cocina::ToFedora::Identity.apply_release_tags(fedora_object, release_tags: cocina_object.administrative&.releaseTags) if has_changed?(:administrative)

      fedora_object.catkey = catkey_for(cocina_object)
      fedora_object.admin_policy_object_id = cocina_object.administrative.hasAdminPolicy if has_changed?(:administrative)

      Cocina::ToFedora::CollectionAccess.apply(fedora_object, cocina_object.access) if has_changed?(:access)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def update_dro
      fedora_object.admin_policy_object_id = cocina_object.administrative.hasAdminPolicy if has_changed?(:administrative)
      fedora_object.collection_ids = Array.wrap(cocina_object.structural&.isMemberOf).compact if has_changed?(:structural)

      if has_changed?(:label)
        fedora_object.label = truncate_label(cocina_object.label)
        Cocina::ToFedora::Identity.apply_label(fedora_object, label: cocina_object.label)
      end

      identity_updater = Cocina::ToFedora::Identity.new(fedora_object)
      if has_changed?(:identification)
        identity_updater.apply_doi(cocina_object.identification.doi)
        fedora_object.source_id = cocina_object.identification.sourceId
        fedora_object.catkey = catkey_for(cocina_object)
        fedora_object.identityMetadata.barcode = cocina_object.identification.barcode
      end

      identity_updater.apply_release_tags(cocina_object.administrative&.releaseTags) if has_changed?(:administrative)

      Cocina::ToFedora::DROAccess.apply(fedora_object, cocina_object.access, cocina_object.structural) if has_changed?(:access) || has_changed?(:structural)
      update_content_metadata(fedora_object, cocina_object) if has_changed?(:structural) || has_changed?(:type)

      fedora_object.geoMetadata.content = cocina_object.geographic.iso19139 if cocina_object&.geographic&.iso19139 && has_changed?(:geographic)

      add_tags(fedora_object.pid, cocina_object)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def update_content_metadata(fedora_object, cocina_object)
      # We don't want to overwrite contentMetadata unless they provided structural.contains
      # Note that a change to a book content type will generate completely new structural metadata, and
      # thus lead to a full replacement of the contentMetadata with the new bookData node.
      if cocina_object.structural&.contains
        fedora_object.contentMetadata.content = Cocina::ToFedora::ContentMetadataGenerator.generate(druid: fedora_object.pid, type: cocina_object.type, structural: cocina_object.structural)
      else
        # remove bookData reading order node if no reading direction is specified in the cocina model
        # ...this can happen if the content type is changed from a book type to a non-book type
        fedora_object.contentMetadata.ng_xml.xpath('//bookData').each(&:remove) unless cocina_object.structural&.hasMemberOrders
        fedora_object.contentMetadata.contentType = ToFedora::ContentType.map(cocina_object.type)
      end
    end

    def update_descriptive
      fedora_object.descMetadata.content = Cocina::ToFedora::Descriptive.transform(cocina_object.description, fedora_object.pid).doc.to_xml
      fedora_object.descMetadata.content_will_change!
    end

    # rubocop:disable Style/GuardClause
    def validate
      validator = ValidateDarkService.new(cocina_object)
      raise ValidationError, validator.error unless validator.valid?

      raise ValidationError, "Identifier on the query and in the body don't match" if fedora_object.pid != cocina_object.externalIdentifier

      validator = ApoExistenceValidator.new(cocina_object)
      raise ValidationError, validator.error unless validator.valid?

      raise NotImplemented, 'Updating descriptive metadata not supported' if !update_descriptive? && client_attempted_metadata_update?

      if has_changed?(:description) && update_descriptive? && Settings.enabled_features.validate_descriptive_roundtrip.update
        result = DescriptionRoundtripValidator.valid_from_cocina?(cocina_object)
        raise RoundtripValidationError, result.failure unless result.success?
      end
    end
    # rubocop:enable Style/GuardClause

    def update_descriptive?
      Settings.enabled_features.update_descriptive || trial
    end

    def client_attempted_metadata_update?
      title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: fedora_object.label)

      descriptive = FromFedora::Descriptive.props(title_builder: title_builder, mods: fedora_object.descMetadata.ng_xml, druid: fedora_object.pid)

      cocina_object.description.title != descriptive.fetch(:title).map { |value| Cocina::Models::Title.new(value) }
    end

    # TODO: duplicate from ObjectCreator
    def catkey_for(cocina_object)
      cocina_object.identification&.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

    def add_tags(pid, cocina_object)
      if has_changed?(:structural)
        # This is necessary so that the content type tag for a book can get updated
        # to reflect the new direction if the direction hash changed in the structural metadata.
        tag = ToFedora::ProcessTag.map(cocina_object.type, cocina_object.structural&.hasMemberOrders&.first&.viewingDirection)
        add_tag(pid, tag, 'Process : Content Type') if tag
      end
      add_tag(pid, "Project : #{cocina_object.administrative.partOfProject}", 'Project') if cocina_object.administrative.partOfProject && has_changed?(:administrative)
    end

    def add_tag(pid, new_tag, prefix)
      return if trial
      raise "Must provide a #{prefix} tag for #{pid}" unless new_tag

      existing_tags = tags_starting_with(pid, prefix)
      if existing_tags.empty?
        AdministrativeTags.create(pid: pid, tags: [new_tag])
      elsif existing_tags.size > 1
        raise "Too many tags for prefix #{prefix}. Expected one."
      elsif existing_tags.first != new_tag
        AdministrativeTags.update(pid: pid, current: existing_tags.first, new: new_tag)
      end
    end

    def tags_starting_with(pid, prefix)
      # This lets us find tags like "Project : Hydrus" when "Project" is the prefix, but will not match on tags like "Project : Hydrus : IR : data"
      prefix_count = prefix.count(':') + 1
      AdministrativeTags.for(pid: pid).select do |tag|
        tag.start_with?(prefix) && tag.count(':') == prefix_count
      end
    end

    # TODO: duplicate from ObjectCreator
    def truncate_label(label)
      label.length > 254 ? label[0, 254] : label
    end
  end
end

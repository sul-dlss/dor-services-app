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

    # rubocop:disable Metrics/AbcSize
    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    def run(event_factory:, notifier: nil)
      @orig_cocina_object = Mapper.build(fedora_object, notifier: notifier)

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
    # rubocop:enable Metrics/AbcSize

    private

    attr_reader :cocina_object, :fedora_object, :params, :orig_cocina_object, :trial

    def has_changed?(key)
      return true if trial

      # Update only if changed.
      cocina_object.public_send(key) != orig_cocina_object.public_send(key)
    end

    # rubocop:disable Style/GuardClause
    def update_apo
      # fedora_object.source_id = cocina_object.identification.sourceId
      if has_changed?(:label)
        Cocina::ToFedora::Identity.apply(fedora_object, label: cocina_object.label)
        fedora_object.label = truncate_label(cocina_object.label)
      end

      if has_changed?(:administrative)
        fedora_object.admin_policy_object_id = cocina_object.administrative.hasAdminPolicy
        Cocina::ToFedora::DefaultRights.write(fedora_object.defaultObjectRights, cocina_object.administrative.defaultAccess) if cocina_object.administrative.defaultAccess
        Cocina::ToFedora::ApoRights.write(fedora_object.administrativeMetadata, cocina_object.administrative)
        Cocina::ToFedora::Roles.write(fedora_object, Array(cocina_object.administrative.roles))
      end
    end
    # rubocop:enable Style/GuardClause

    def update_collection
      if has_changed?(:label)
        fedora_object.label = truncate_label(cocina_object.label)
        Cocina::ToFedora::Identity.apply(fedora_object, label: cocina_object.label)
      end
      fedora_object.admin_policy_object_id = cocina_object.administrative.hasAdminPolicy if has_changed?(:administrative)

      Cocina::ToFedora::Access.apply(fedora_object, cocina_object.access) if has_changed?(:access)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def update_dro
      fedora_object.admin_policy_object_id = cocina_object.administrative.hasAdminPolicy if has_changed?(:administrative)
      fedora_object.collection_ids = Array.wrap(cocina_object.structural&.isMemberOf).compact if has_changed?(:structural)
      fedora_object.label = truncate_label(cocina_object.label) if has_changed?(:label)

      if has_changed?(:identification)
        fedora_object.source_id = cocina_object.identification.sourceId
        fedora_object.catkey = catkey_for(cocina_object)
        fedora_object.identityMetadata.barcode = cocina_object.identification.barcode
      end

      if has_changed?(:label) || has_changed?(:structural)
        label = has_changed?(:label) ? cocina_object.label : fedora_object.label
        agreement_id = has_changed?(:structural) ? cocina_object.structural&.hasAgreement : nil
        Cocina::ToFedora::Identity.apply(fedora_object, label: label, agreement_id: agreement_id)
      end
      Cocina::ToFedora::DROAccess.apply(fedora_object, cocina_object.access) if has_changed?(:access)
      update_content_metadata(fedora_object, cocina_object) if has_changed?(:structural) || has_changed?(:type)

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
        fedora_object.contentMetadata.content = Cocina::ToFedora::ContentMetadataGenerator.generate(druid: fedora_object.pid, object: cocina_object)
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
      Settings.enabled_features.update_descriptive
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
      add_tag(pid, ToFedora::ProcessTag.map(cocina_object.type, cocina_object.structural&.hasMemberOrders&.first&.viewingDirection), 'Process : Content Type') if has_changed?(:structural)
      add_tag(pid, "Project : #{cocina_object.administrative.partOfProject}", 'Project') if cocina_object.administrative.partOfProject && has_changed?(:administrative)
    end

    def add_tag(pid, new_tag, prefix)
      return if trial
      raise "Must provide a #{prefix} tag for #{pid}" unless new_tag

      existing_tag = tag_starting_with(pid, prefix)
      if existing_tag.nil?
        AdministrativeTags.create(pid: pid, tags: [new_tag])
      elsif existing_tag != new_tag
        AdministrativeTags.update(pid: pid, current: existing_tag, new: new_tag)
      end
    end

    def tag_starting_with(pid, prefix)
      AdministrativeTags.for(pid: pid).each do |tag|
        return tag if tag.start_with?(prefix)
      end
      nil
    end

    # TODO: duplicate from ObjectCreator
    def truncate_label(label)
      label.length > 254 ? label[0, 254] : label
    end
  end
end

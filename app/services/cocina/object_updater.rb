# frozen_string_literal: true

module Cocina
  # This takes a cocina object and updates the corresponding ActiveFedora object
  # with the provided values
  class ObjectUpdater
    class NotImplemented < StandardError; end

    # @param [ActiveFedora::Base] item the object to update
    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] obj the cocina model provided by the client
    # @param [#create] event_factory creates events
    # @param [boolean] trial do not persist or event; run all mappings regardless of changes
    # @param [Cocina::FromFedora::DataErrorNotifier] notifier
    def self.run(item, obj, event_factory: EventFactory, trial: false, notifier: nil)
      new(item, obj, trial: trial).run(event_factory: event_factory, notifier: notifier)
    end

    def initialize(item, obj, trial: false)
      @params = params
      @obj = obj
      @item = item
      @trial = trial
    end

    # rubocop:disable Metrics/AbcSize
    def run(event_factory:, notifier: nil)
      @orig_obj = Mapper.build(item, notifier: notifier)

      # Validate will raise an error if not valid.
      validate unless trial

      case obj
      when Cocina::Models::AdminPolicy
        update_apo
      when Cocina::Models::DRO
        update_dro
      when Cocina::Models::Collection
        update_collection
      else
        raise "unsupported type #{obj.type}"
      end

      update_descriptive if has_changed?(:description) && update_descriptive?

      item.save! unless trial

      event_factory.create(druid: item.pid, event_type: 'update_complete', data: { success: true }) unless trial

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      Mapper.build(item, notifier: notifier).tap do
        event_factory.create(druid: item.pid, event_type: 'update', data: { success: true, request: obj.to_h }) unless trial
      end
    rescue Mapper::MapperError, ValidationError, NotImplemented => e
      event_factory.create(druid: item.pid, event_type: 'update', data: { success: false, error: e.message, request: obj.to_h }) unless trial
      raise
    end
    # rubocop:enable Metrics/AbcSize

    private

    attr_reader :obj, :item, :params, :orig_obj, :trial

    def has_changed?(key)
      return true if trial

      # Update only if changed.
      obj.public_send(key) != orig_obj.public_send(key)
    end

    # rubocop:disable Style/GuardClause
    def update_apo
      # item.source_id = obj.identification.sourceId
      if has_changed?(:label)
        Cocina::ToFedora::Identity.apply(item, label: obj.label, object_type: 'adminPolicy')
        item.label = truncate_label(obj.label)
      end

      if has_changed?(:administrative)
        item.admin_policy_object_id = obj.administrative.hasAdminPolicy
        Cocina::ToFedora::DefaultRights.write(item.defaultObjectRights, obj.administrative.defaultAccess) if obj.administrative.defaultAccess
        Cocina::ToFedora::ApoRights.write(item.administrativeMetadata, obj.administrative)
        Cocina::ToFedora::Roles.write(item, Array(obj.administrative.roles))
      end
    end
    # rubocop:enable Style/GuardClause

    def update_collection
      if has_changed?(:label)
        item.label = truncate_label(obj.label)
        Cocina::ToFedora::Identity.apply(item, label: obj.label, object_type: 'collection')
      end
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy if has_changed?(:administrative)

      Cocina::ToFedora::Access.apply(item, obj.access) if has_changed?(:access)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def update_dro
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy if has_changed?(:administrative)
      item.collection_ids = Array.wrap(obj.structural&.isMemberOf).compact if has_changed?(:structural)
      item.label = truncate_label(obj.label) if has_changed?(:label)

      if has_changed?(:identification)
        item.source_id = obj.identification.sourceId
        item.catkey = catkey_for(obj)
        item.identityMetadata.barcode = obj.identification.barcode
      end

      if has_changed?(:label) || has_changed?(:structural)
        label = has_changed?(:label) ? obj.label : item.label
        agreement_id = has_changed?(:structural) ? obj.structural&.hasAgreement : nil
        Cocina::ToFedora::Identity.apply(item, label: label, object_type: 'item', agreement_id: agreement_id)
      end
      Cocina::ToFedora::DROAccess.apply(item, obj.access) if has_changed?(:access)
      update_content_metadata(item, obj) if has_changed?(:structural) || has_changed?(:type)

      add_tags(item.pid, obj)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def update_content_metadata(item, obj)
      # We don't want to overwrite contentMetadata unless they provided structural.contains
      if obj.structural&.contains
        item.contentMetadata.content = Cocina::ToFedora::ContentMetadataGenerator.generate(druid: item.pid, object: obj)
      else
        item.contentMetadata.contentType = ToFedora::ContentType.map(obj.type)
      end
    end

    def update_descriptive
      item.descMetadata.content = Cocina::ToFedora::Descriptive.transform(obj.description, item.pid).doc.to_xml
      item.descMetadata.content_will_change!
    end

    # rubocop:disable Style/GuardClause
    def validate
      validator = ValidateDarkService.new(obj)
      raise ValidationError, validator.error unless validator.valid?

      raise ValidationError, "Identifier on the query and in the body don't match" if item.pid != obj.externalIdentifier

      validator = ApoExistenceValidator.new(obj)
      raise ValidationError, validator.error unless validator.valid?

      raise NotImplemented, 'Updating descriptive metadata not supported' if !update_descriptive? && client_attempted_metadata_update?

      if has_changed?(:description) && update_descriptive? && Settings.enabled_features.validate_descriptive_roundtrip.update
        result = DescriptionRoundtripValidator.valid_from_cocina?(obj)
        raise RoundtripValidationError, result.failure unless result.success?
      end
    end
    # rubocop:enable Style/GuardClause

    def update_descriptive?
      Settings.enabled_features.update_descriptive
    end

    def client_attempted_metadata_update?
      title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: item.label)

      descriptive = FromFedora::Descriptive.props(title_builder: title_builder, mods: item.descMetadata.ng_xml, druid: item.pid)

      obj.description.title != descriptive.fetch(:title).map { |value| Cocina::Models::Title.new(value) }
    end

    # TODO: duplicate from ObjectCreator
    def catkey_for(obj)
      obj.identification&.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

    def add_tags(pid, obj)
      add_tag(pid, ToFedora::ProcessTag.map(obj.type, obj.structural&.hasMemberOrders&.first&.viewingDirection), 'Process : Content Type') if has_changed?(:structural)
      add_tag(pid, "Project : #{obj.administrative.partOfProject}", 'Project') if obj.administrative.partOfProject && has_changed?(:administrative)
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

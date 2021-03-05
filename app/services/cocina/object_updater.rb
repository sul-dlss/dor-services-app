# frozen_string_literal: true

module Cocina
  # This takes a cocina object and updates the corresponding ActiveFedora object
  # with the provided values
  class ObjectUpdater
    class NotImplemented < StandardError; end

    # @param [ActiveFedora::Base] item the object to update
    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] obj the cocina model provided by the client
    # @param [Array<String>] only only update the provided keys if provided
    # @param [#create] event_factory creates events
    def self.run(item, obj, event_factory: EventFactory, only: nil)
      new(item, obj, only: only).run(event_factory: event_factory)
    end

    def initialize(item, obj, only: nil)
      @params = params
      @obj = obj
      @item = item
      @only = only ? only.map(&:to_sym) : nil
    end

    def run(event_factory:)
      # Validate will raise an error if not valid.
      validate

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

      update_descriptive if update?(:description) && update_descriptive?

      item.save!

      event_factory.create(druid: item.pid, event_type: 'update_complete', data: { success: true })

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      Mapper.build(item).tap do
        event_factory.create(druid: item.pid, event_type: 'update', data: { success: true, request: obj.to_h })
      end
    rescue Mapper::MapperError, ValidationError, NotImplemented => e
      event_factory.create(druid: item.pid, event_type: 'update', data: { success: false, error: e.message, request: obj.to_h })
      raise
    end

    private

    attr_reader :obj, :item, :params, :only

    def update?(key)
      only.nil? || only.include?(key)
    end

    # rubocop:disable Style/GuardClause
    def update_apo
      # item.source_id = obj.identification.sourceId
      if update?(:label)
        Cocina::ToFedora::Identity.apply(item, label: obj.label, object_type: 'adminPolicy')
        item.label = truncate_label(obj.label)
      end

      if update?(:administrative)
        item.admin_policy_object_id = obj.administrative.hasAdminPolicy if update?(:administrative)
        Cocina::ToFedora::ApoRights.write(item.administrativeMetadata, obj.administrative)
      end
    end
    # rubocop:enable Style/GuardClause

    def update_collection
      if update?(:label)
        item.label = truncate_label(obj.label)
        Cocina::ToFedora::Identity.apply(item, label: obj.label, object_type: 'collection')
      end
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy if update?(:administrative)

      Cocina::ToFedora::Access.apply(item, obj.access) if update?(:access)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def update_dro
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy if update?(:administrative)
      item.collection_ids = Array.wrap(obj.structural&.isMemberOf).compact if update?(:structural)
      item.label = truncate_label(obj.label) if update?(:label)

      if update?(:identification)
        item.source_id = obj.identification.sourceId
        item.catkey = catkey_for(obj)
      end

      if update?(:label) || update?(:structural)
        label = update?(:label) ? obj.label : item.label
        agreement_id = update?(:structural) ? obj.structural&.hasAgreement : nil
        Cocina::ToFedora::Identity.apply(item, label: label, object_type: 'item', agreement_id: agreement_id)
      end

      Cocina::ToFedora::DROAccess.apply(item, obj.access) if update?(:access)
      update_content_metadata(item, obj) if update?(:structural)

      add_tags(item.id, obj)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity

    def update_content_metadata(item, obj)
      # We don't want to overwrite contentMetadata unless they provided structural.contains
      if obj.structural&.contains
        item.contentMetadata.content = Cocina::ToFedora::ContentMetadataGenerator.generate(druid: item.pid, object: obj)
      else
        item.contentMetadata.contentType = ToFedora::ContentType.map(obj.type)
      end
    end

    def update_descriptive
      item.descMetadata.content = Cocina::ToFedora::Descriptive.transform(obj.description, item.pid).to_xml
      item.descMetadata.content_will_change!
    end

    def validate
      validator = ValidateDarkService.new(obj)
      raise ValidationError, validator.error unless validator.valid?

      raise ValidationError, "Identifier on the query and in the body don't match" if item.pid != obj.externalIdentifier

      validator = Cocina::ApoExistenceValidator.new(obj)
      raise ValidationError, validator.error unless validator.valid?

      raise NotImplemented, 'Updating descriptive metadata not supported' if !update_descriptive? && client_attempted_metadata_update?
    end

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
      add_tag(pid, ToFedora::ProcessTag.map(obj.type, obj.structural&.hasMemberOrders&.first&.viewingDirection), 'Process : Content Type') if update?(:structural)
      add_tag(pid, "Project : #{obj.administrative.partOfProject}", 'Project') if obj.administrative.partOfProject && update?(:administrative)
    end

    def add_tag(pid, new_tag, prefix)
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

# frozen_string_literal: true

module Cocina
  # This takes a cocina object and updates the corresponding ActiveFedora object
  # with the provided values
  class ObjectUpdater
    class NotImplemented < StandardError; end

    # @param [ActiveFedora::Base] item
    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] obj the cocina model
    # @param [#create] event_factory creates events
    def self.run(item, obj, event_factory: EventFactory)
      new(item, obj).run(event_factory: event_factory)
    end

    def initialize(item, obj)
      @params = params
      @obj = obj
      @item = item
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

      item.save!

      event_factory.create(druid: item.pid, event_type: 'update', data: obj.to_h)

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      Mapper.build(item)
    end

    private

    attr_reader :obj, :item, :params

    def update_apo
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy
      # item.source_id = obj.identification.sourceId
      item.label = truncate_label(obj.label)

      admin_node = item.administrativeMetadata.ng_xml.xpath('//administrativeMetadata').first
      # TODO: need to see if this node already exists
      admin_node.add_child "<dissemination><workflow id=\"#{obj.administrative.registrationWorkflow}\"></dissemination>"
      item.administrativeMetadata.ng_xml_will_change!

      Cocina::ToFedora::Identity.apply(obj, item, object_type: 'adminPolicy')
    end

    def update_collection
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy
      item.catkey = catkey_for(obj)
      item.label = truncate_label(obj.label)

      Cocina::ToFedora::Identity.apply(obj, item, object_type: 'collection')
    end

    # rubocop:disable Metrics/AbcSize
    def update_dro
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy
      item.source_id = obj.identification.sourceId
      item.collection_ids = [obj.structural&.isMemberOf].compact
      item.catkey = catkey_for(obj)
      item.label = truncate_label(obj.label)

      add_tags(item.id, obj)

      Cocina::ToFedora::Access.apply(item, obj.access)
      item.rightsMetadata.copyright = obj.access.copyright if obj.access.copyright
      item.rightsMetadata.use_statement = obj.access.useAndReproductionStatement if obj.access.useAndReproductionStatement
      update_content_metadata(item, obj)
      Cocina::ToFedora::Identity.apply(obj, item, object_type: 'item', agreement_id: obj.structural&.hasAgreement)
    end
    # rubocop:enable Metrics/AbcSize

    def update_content_metadata(item, obj)
      # We don't want to overwrite contentMetadata unless they provided structural.contains
      if obj.structural&.contains
        item.contentMetadata.content = ContentMetadataGenerator.generate(druid: item.pid, object: obj)
      else
        item.contentMetadata.contentType = ToFedora::ContentType.map(obj.type)
      end
    end

    def validate
      validator = ValidateDarkService.new(obj)
      raise ValidationError, validator.error unless validator.valid?

      raise ValidationError, "Identifier on the query and in the body don't match" if item.pid != obj.externalIdentifier

      validator = Cocina::ApoExistenceValidator.new(obj)
      raise ValidationError, validator.error unless validator.valid?

      # Can't currently roundtrip desc metadata, including title.
      # Note that title is the only desc metadata field handled by the mapper. However, the mapped title is composed from
      # several MODS fields which makes writing back to the MODS problematic.
      raise NotImplemented, 'Updating descriptive metadata not supported' if obj.description.title.first.value != FromFedora::TitleMapper.build(item)
    end

    # TODO: duplicate from ObjectCreator
    def catkey_for(obj)
      obj.identification&.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

    def add_tags(pid, obj)
      add_tag(pid, ToFedora::ProcessTag.map(obj.type, obj.structural&.hasMemberOrders&.first&.viewingDirection), 'Process : Content Type')
      add_tag(pid, "Project : #{obj.administrative.partOfProject}", 'Project') if obj.administrative.partOfProject
    end

    def add_tag(pid, new_tag, prefix)
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

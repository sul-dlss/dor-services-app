# frozen_string_literal: true

module Cocina
  # Given a Cocina model, create an ActiveFedora model.
  class ObjectCreator
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def self.create(obj, event_factory: EventFactory, persister: ActiveFedoraPersister)
      new.create(obj, event_factory: event_factory, persister: persister)
    end

    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] obj
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def create(obj, event_factory:, persister:)
      # Validate will raise an error if not valid.
      ObjectValidator.validate(obj)

      af_model = create_from_model(obj, persister: persister)

      # Fedora 3 has no unique constrains, so
      # index right away to reduce the likelyhood of duplicate sourceIds
      SynchronousIndexer.reindex_remotely(af_model.pid)

      event_factory.create(druid: af_model.pid, event_type: 'registration', data: obj.to_h)

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      Mapper.build(af_model)
    end

    private

    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] obj
    # @param [#store] persister the service responsible for persisting the model
    # @return [Dor::Abstract] a persisted ActiveFedora model
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def create_from_model(obj, persister:)
      af_object = case obj
                  when Cocina::Models::RequestAdminPolicy
                    create_apo(obj)
                  when Cocina::Models::RequestDRO
                    create_dro(obj)
                  when Cocina::Models::RequestCollection
                    create_collection(obj)
                  else
                    raise "unsupported type #{obj.type}"
                  end

      persister.store(af_object)
      af_object
    end

    # @param [Cocina::Models::RequestAdminPolicy] obj
    # @return [Dor::AdminPolicyObject] a persisted APO model
    def create_apo(obj)
      pid = Dor::SuriService.mint_id
      Dor::AdminPolicyObject.new(pid: pid,
                                 admin_policy_object_id: obj.administrative.hasAdminPolicy,
                                 # source_id: obj.identification.sourceId,
                                 label: obj.label).tap do |item|
        add_description(item, obj)

        Cocina::ToFedora::ApoRights.write(item.administrativeMetadata, obj.administrative)
        Cocina::ToFedora::Identity.apply(item, label: obj.label, object_type: 'adminPolicy')
      end
    end

    # @param [Cocina::Models::RequestDRO] obj
    # @return [Dor::Item] a persisted Item model
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def create_dro(obj)
      pid = Dor::SuriService.mint_id
      Dor::Item.new(pid: pid,
                    admin_policy_object_id: obj.administrative.hasAdminPolicy,
                    source_id: obj.identification.sourceId,
                    collection_ids: Array.wrap(obj.structural&.isMemberOf).compact,
                    catkey: catkey_for(obj),
                    label: truncate_label(obj.label)).tap do |item|
        add_description(item, obj)
        add_dro_tags(pid, obj)

        apply_default_access(item)
        Cocina::ToFedora::DROAccess.apply(item, obj.access) if obj.access

        item.contentMetadata.content = Cocina::ToFedora::ContentMetadataGenerator.generate(druid: pid, object: obj)
        Cocina::ToFedora::Identity.apply(item, label: obj.label, object_type: 'item', agreement_id: obj.structural&.hasAgreement)
      end
    end

    # @param [Cocina::Models::RequestCollection] obj
    # @return [Dor::Collection] a persisted Collection model
    def create_collection(obj)
      pid = Dor::SuriService.mint_id
      Dor::Collection.new(pid: pid,
                          admin_policy_object_id: obj.administrative.hasAdminPolicy,
                          source_id: obj.identification&.sourceId,
                          catkey: catkey_for(obj),
                          label: truncate_label(obj.label)).tap do |item|
        add_description(item, obj)
        add_collection_tags(pid, obj)
        apply_default_access(item)
        Cocina::ToFedora::Access.apply(item, obj.access) if obj.access
        Cocina::ToFedora::Identity.apply(item, label: obj.label, object_type: 'collection')
      end
    end

    def catkey_for(obj)
      obj.identification&.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

    # @param [Dor::[Item|Collection|APO]] item
    # @param [Cocina:Models::Request[DOR|Collection|xxx]] obj
    # @raises SymphonyReader::ResponseError if symphony connection failed
    def add_description(item, obj)
      # Hydrus doesn't set description. See https://github.com/sul-dlss/hydrus/issues/421
      return if obj.label == 'Hydrus'

      # Synch from symphony if a catkey is present
      if item.catkey
        RefreshMetadataAction.run(identifiers: ["catkey:#{item.catkey}"], datastream: item.descMetadata)
        label = MetadataService.label_from_mods(item.descMetadata.ng_xml)
        item.label = truncate_label(label)
        item.objectLabel = label
      elsif obj.description
        description = AddPurlToDescription.call(obj.description, item.pid)
        item.descMetadata.content = Cocina::ToFedora::Descriptive.transform(description, item.pid).to_xml
        item.descMetadata.content_will_change!
      else
        item.descMetadata.mods_title = obj.label
      end
    end

    def add_dro_tags(pid, obj)
      tags = []
      process_tag = ToFedora::ProcessTag.map(obj.type, obj.structural&.hasMemberOrders&.first&.viewingDirection)
      tags << process_tag if process_tag
      tags << "Project : #{obj.administrative.partOfProject}" if obj.administrative.partOfProject
      AdministrativeTags.create(pid: pid, tags: tags) if tags.any?
    end

    def add_collection_tags(pid, obj)
      return unless obj.administrative.partOfProject

      AdministrativeTags.create(pid: pid, tags: ["Project : #{obj.administrative.partOfProject}"])
    end

    # Copy the default rights, use statement and copyright statement from the
    # admin policy to the provided item.  If the user provided the access
    # subschema, they may overwrite some of these defaults.
    def apply_default_access(item)
      apo = Dor.find(item.admin_policy_object_id)
      rights_xml = apo.defaultObjectRights.ng_xml
      item.rightsMetadata.content = rights_xml.to_s
    end

    def truncate_label(label)
      label.length > 254 ? label[0, 254] : label
    end
  end
end

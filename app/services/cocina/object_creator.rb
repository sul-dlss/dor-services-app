# frozen_string_literal: true

module Cocina
  # Given a Cocina model, create an ActiveFedora model.
  class ObjectCreator
    def self.create(params, event_factory: EventFactory)
      new.create(params, event_factory: event_factory)
    end

    def create(params, event_factory:)
      obj = Cocina::Models.build_request(params)

      # Validate will raise an error if not valid.
      validate(obj)
      af_model = create_from_model(obj)

      event_factory.create(druid: af_model.pid, event_type: 'registration', data: params)

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      Mapper.build(af_model)
    end

    private

    def validate(obj)
      if obj.is_a?(Cocina::Models::RequestDRO) && Dor::SearchService.query_by_id(obj.identification.sourceId).first
        raise Dor::DuplicateIdError.new(obj.identification.sourceId), "An object with the source ID '#{obj.identification.sourceId}' has already been registered."
      end

      # Validate APO exists (this raises an error if it doesn't)
      Dor.find(obj.administrative.hasAdminPolicy)
    end

    # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] obj
    # @return [Dor::Abstract] a persisted ActiveFedora model
    def create_from_model(obj)
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

      # Synch from symphony if a catkey is present
      if af_object.catkey
        RefreshMetadataAction.run(identifiers: ["catkey:#{af_object.catkey}"], datastream: af_object.descMetadata)
        af_object.label = MetadataService.label_from_mods(af_object.descMetadata.ng_xml)
      end

      af_object.save!
      af_object
    end

    # @param [Cocina::Models::RequestAdminPolicy] obj
    # @return [Dor::AdminPolicyObject] a persisted APO model
    def create_apo(obj)
      Dor::AdminPolicyObject.new(pid: Dor::SuriService.mint_id,
                                 admin_policy_object_id: obj.administrative.hasAdminPolicy,
                                 # source_id: obj.identification.sourceId,
                                 label: obj.label).tap do |item|
        item.descMetadata.mods_title = obj.description.title.first.titleFull if obj.description

        admin_node = item.administrativeMetadata.ng_xml.xpath('//administrativeMetadata').first
        admin_node.add_child "<dissemination><workflow id=\"#{obj.administrative.registration_workflow}\"></dissemination>"
        item.administrativeMetadata.ng_xml_will_change!
      end
    end

    # @param [Cocina::Models::RequestDRO] obj
    # @return [Dor::Item] a persisted Item model
    def create_dro(obj)
      pid = Dor::SuriService.mint_id
      Dor::Item.new(pid: pid,
                    admin_policy_object_id: obj.administrative.hasAdminPolicy,
                    source_id: obj.identification.sourceId,
                    catkey: catkey_for(obj),
                    label: obj.label).tap do |item|
        item.descMetadata.mods_title = obj.description.title.first.titleFull if obj.description
        item.identityMetadata.tag = content_type_tag(obj.type, obj.structural.hasMemberOrders&.first&.viewingDirection)
        change_access(item, obj.access.access)
        item.rightsMetadata.copyright = obj.access.copyright if obj.access.copyright
        item.rightsMetadata.use_statement = obj.access.useAndReproductionStatement if obj.access.useAndReproductionStatement

        item.contentMetadata.content = ContentMetadataGenerator.generate(druid: pid, object: obj)
        if obj.access.embargo
          EmbargoService.embargo(item: item,
                                 release_date: obj.access.embargo.releaseDate,
                                 access: obj.access.embargo.access)
        end
      end
    end

    # @param [Cocina::Models::RequestCollection] obj
    # @return [Dor::Collection] a persisted Collection model
    def create_collection(obj)
      Dor::Collection.new(pid: Dor::SuriService.mint_id,
                          admin_policy_object_id: obj.administrative.hasAdminPolicy,
                          catkey: catkey_for(obj),
                          label: obj.label).tap do |item|
        item.descMetadata.mods_title = obj.description.title.first.titleFull if obj.description
      end
    end

    def catkey_for(obj)
      obj.identification.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

    def content_type_tag(type, direction)
      tag = case type
            when Cocina::Models::Vocab.image
              'Image'
            when Cocina::Models::Vocab.three_dimensional
              '3D'
            when Cocina::Models::Vocab.map
              'Map'
            when Cocina::Models::Vocab.media
              'Media'
            when Cocina::Models::Vocab.manuscript
              'Manuscript'
            when Cocina::Models::Vocab.book
              short_dir = direction == 'right-to-left' ? 'rtl' : 'ltr'
              "Book (#{short_dir})"
            else
              Cocina::Models::Vocab.object
            end
      "Process : Content Type : #{tag}"
    end

    def change_access(item, access)
      raise 'location-based access not implemented' if access == 'location-based'

      # See https://github.com/sul-dlss/dor-services/blob/master/lib/dor/datastreams/rights_metadata_ds.rb
      rights_type = access == 'citation-only' ? 'none' : access
      Dor::RightsMetadataDS.upd_rights_xml_for_rights_type(item.rightsMetadata.ng_xml, rights_type)
      item.rightsMetadata.ng_xml_will_change!
    end
  end
end

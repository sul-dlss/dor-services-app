# frozen_string_literal: true

module Cocina
  # Given a Cocina model, create an ActiveFedora model.
  class ObjectCreator
    # TODO: We shouldn't need to provide a bogus externalIdentifier
    def self.create(params)
      new.create(params)
    end

    def create(params)
      obj = case params[:type]
            when *Cocina::Models::DRO::TYPES
              build_dro(params)
            when *Cocina::Models::Collection::TYPES
              build_collection(params)
            when *Cocina::Models::AdminPolicy::TYPES
              build_apo(params)
            else
              raise "Unknown type #{params[:type]}"
            end
      if validate(obj)
        af_model = create_from_model(obj)

        # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
        return Mapper.build(af_model)
      end

      raise 'not valid'
    end

    private

    def build_dro(params)
      Cocina::Models::DRO.from_dynamic(params)
    end

    def build_collection(params)
      Cocina::Models::Collection.from_dynamic(params)
    end

    def build_apo(params)
      Cocina::Models::AdminPolicy.from_dynamic(params)
    end

    def validate(obj)
      if obj.dro? && Dor::SearchService.query_by_id(obj.identification.sourceId).first
        raise Dor::DuplicateIdError.new(obj.identification.sourceId), "An object with the source ID '#{obj.identification.sourceId}' has already been registered."
      end

      # Validate APO exists (this raises an error if it doesn't)
      Dor.find(obj.administrative.hasAdminPolicy)
    end

    def create_from_model(obj)
      af_object = if obj.admin_policy?
                    create_apo(obj)
                  elsif obj.dro?
                    create_dro(obj)
                  elsif obj.collection?
                    create_collection(obj)
                  else
                    raise "unsupported type #{obj.type}"
                  end

      # TODO: Synch from symphony if a catkey is present
      # RefreshMetadataAction.run(identifiers: identifiers, datastream: af_object.descMetadata)

      af_object.save!
      af_object
    end

    def create_apo(obj)
      Dor::AdminPolicyObject.new(pid: Dor::SuriService.mint_id,
                                 admin_policy_object_id: obj.administrative.hasAdminPolicy,
                                 # source_id: obj.identification.sourceId,
                                 label: obj.label).tap do |item|
        item.descMetadata.mods_title = obj.description.title.first.titleFull

        admin_node = item.administrativeMetadata.ng_xml.xpath('//administrativeMetadata').first
        admin_node.add_child "<dissemination><workflow id=\"#{obj.administrative.registration_workflow}\"></dissemination>"
        item.administrativeMetadata.ng_xml_will_change!
      end
    end

    def create_dro(obj)
      Dor::Item.new(pid: Dor::SuriService.mint_id,
                    admin_policy_object_id: obj.administrative.hasAdminPolicy,
                    source_id: obj.identification.sourceId,
                    label: obj.label).tap do |item|
        item.descMetadata.mods_title = obj.description.title.first.titleFull
        item.identityMetadata.tag = content_type_tag(obj.type)
      end
    end

    def create_collection(obj)
      Dor::Collection.new(pid: Dor::SuriService.mint_id,
                          admin_policy_object_id: obj.administrative.hasAdminPolicy,
                          label: obj.label).tap do |item|
        item.descMetadata.mods_title = obj.description.title.first.titleFull
      end
    end

    def content_type_tag(type)
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
              'Book'
            else
              Cocina::Models::Vocab.object
            end
      "Process : Content Type : #{tag}"
    end
  end
end

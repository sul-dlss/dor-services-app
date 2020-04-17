# frozen_string_literal: true

module Cocina
  # Given a Cocina model, create an ActiveFedora model.
  # rubocop:disable Metrics/ClassLength
  class ObjectCreator
    def self.create(params, event_factory: EventFactory)
      new.create(params, event_factory: event_factory)
    end

    def create(params, event_factory:)
      obj = Cocina::Models.build_request(params)

      # Validate will raise an error if not valid.
      validate(obj)
      af_model = create_from_model(obj)

      # Fedora 3 has no unique constrains, so
      # index right away to reduce the likelyhood of duplicate sourceIds
      SynchronousIndexer.reindex_remotely(af_model.pid)

      event_factory.create(druid: af_model.pid, event_type: 'registration', data: params)

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      Mapper.build(af_model)
    end

    private

    def validate(obj)
      if obj.is_a?(Cocina::Models::RequestDRO)
        if Dor::SearchService.query_by_id(obj.identification.sourceId).first
          raise Dor::DuplicateIdError.new(obj.identification.sourceId), "An object with the source ID '#{obj.identification.sourceId}' has already been registered."
        end

        validator = ValidateDarkService.new(obj)
        raise Dor::ParameterError, "Not all files have dark access and/or are unshelved when item access is dark: #{validator.invalid_filenames}" unless validator.valid?
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

      af_object.save!
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

        admin_node = item.administrativeMetadata.ng_xml.xpath('//administrativeMetadata').first
        admin_node.add_child "<dissemination><workflow id=\"#{obj.administrative.registrationWorkflow}\"></dissemination>"
        item.administrativeMetadata.ng_xml_will_change!

        add_identity_metadata(obj, item, 'adminPolicy')
      end
    end

    # @param [Cocina::Models::RequestDRO] obj
    # @return [Dor::Item] a persisted Item model
    def create_dro(obj)
      pid = Dor::SuriService.mint_id
      Dor::Item.new(pid: pid,
                    admin_policy_object_id: obj.administrative.hasAdminPolicy,
                    source_id: obj.identification.sourceId,
                    collection_ids: [obj.structural&.isMemberOf].compact,
                    catkey: catkey_for(obj),
                    label: truncate_label(obj.label)).tap do |item|
        add_description(item, obj)
        add_dro_tags(item, obj)

        if obj.access
          change_access(item, obj.access)
          item.rightsMetadata.copyright = obj.access.copyright if obj.access.copyright
          item.rightsMetadata.use_statement = obj.access.useAndReproductionStatement if obj.access.useAndReproductionStatement
          create_embargo(item, obj.access.embargo) if obj.access.embargo
        else
          apply_default_access(item)
        end

        item.contentMetadata.content = ContentMetadataGenerator.generate(druid: pid, object: obj) if obj&.structural&.contains

        add_identity_metadata(obj, item, 'item')
      end
    end

    def create_embargo(item, embargo)
      EmbargoService.create(item: item,
                            release_date: embargo.releaseDate,
                            access: embargo.access,
                            use_and_reproduction_statement: embargo.useAndReproductionStatement)
    end

    # @param [Cocina::Models::RequestCollection] obj
    # @return [Dor::Collection] a persisted Collection model
    def create_collection(obj)
      pid = Dor::SuriService.mint_id
      Dor::Collection.new(pid: pid,
                          admin_policy_object_id: obj.administrative.hasAdminPolicy,
                          catkey: catkey_for(obj),
                          label: truncate_label(obj.label)).tap do |item|
        add_description(item, obj)
        add_collection_tags(item, obj)
        add_identity_metadata(obj, item, 'collection')
      end
    end

    def catkey_for(obj)
      obj.identification&.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

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
        item.descMetadata.mods_title = obj.description.title.first.value
      else
        item.descMetadata.mods_title = obj.label
      end
    end

    def add_dro_tags(item, obj)
      tags = [content_type_tag(obj.type, obj.structural&.hasMemberOrders&.first&.viewingDirection)]
      tags << "Project : #{obj.administrative.partOfProject}" if obj.administrative.partOfProject
      AdministrativeTags.create(item: item, tags: tags)
    end

    def add_collection_tags(item, obj)
      return unless obj.administrative.partOfProject

      AdministrativeTags.create(item: item, tags: ["Project : #{obj.administrative.partOfProject}"])
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
      rights_type = case access.access
                    when 'location-based'
                      "loc:#{access.readLocation}"
                    when 'citation-only'
                      'none'
                    else
                      access.download == 'none' ? "#{access.access}-nd" : access.access
                    end

      # See https://github.com/sul-dlss/dor-services/blob/master/lib/dor/datastreams/rights_metadata_ds.rb
      Dor::RightsMetadataDS.upd_rights_xml_for_rights_type(item.rightsMetadata.ng_xml, rights_type)
      item.rightsMetadata.ng_xml_will_change!
    end

    # add the default rights from the admin policy to the provided item
    def apply_default_access(item)
      apo = Dor.find(item.admin_policy_object_id)
      rights_xml = apo.defaultObjectRights.ng_xml
      item.rightsMetadata.content = rights_xml.to_s
    end

    def add_identity_metadata(obj, item, object_type)
      item.objectId = item.pid
      item.objectCreator = 'DOR'
      # May have already been set when setting descriptive metadata.
      item.objectLabel = obj.label if item.objectLabel.empty?
      item.objectType = object_type
      # Not currently mapping other ids.
    end

    def truncate_label(label)
      label.length > 254 ? label[0, 254] : label
    end
  end
  # rubocop:enable Metrics/ClassLength
end

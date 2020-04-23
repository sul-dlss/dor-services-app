# frozen_string_literal: true

module Cocina
  # This takes a cocina object and updates the corresponding ActiveFedora object
  # with the provided values
  class ObjectUpdater
    # @param [ActiveFedora::Base] item
    # @param [Hash] params the cocina model represented as a hash
    # @param [#create] event_factory creates events
    def self.run(item, params, event_factory: EventFactory)
      new(item, params).run(event_factory: event_factory)
    end

    def initialize(item, params)
      @params = params
      @obj = Cocina::Models.build(params)
      @item = item
    end

    def run(event_factory:)
      # Validate will raise an error if not valid.
      validate(obj)

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

      event_factory.create(druid: item.pid, event_type: 'update', data: params)

      # This will rebuild the cocina model from fedora, which shows we are only returning persisted data
      Mapper.build(item)
    end

    private

    attr_reader :obj, :item, :params

    def update_apo
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy
      # item.source_id = obj.identification.sourceId
      item.label = truncate_label(obj.label)

      item.descMetadata.mods_title = obj.description.title.first.value

      admin_node = item.administrativeMetadata.ng_xml.xpath('//administrativeMetadata').first
      # TODO: need to see if this node already exists
      admin_node.add_child "<dissemination><workflow id=\"#{obj.administrative.registrationWorkflow}\"></dissemination>"
      item.administrativeMetadata.ng_xml_will_change!

      add_identity_metadata(obj, item, 'adminPolicy')
    end

    def update_collection
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy
      item.catkey = catkey_for(obj)
      item.label = truncate_label(obj.label)

      item.descMetadata.mods_title = obj.description.title.first.value

      add_identity_metadata(obj, item, 'collection')
    end

    # rubocop:disable Metrics/AbcSize
    def update_dro
      item.admin_policy_object_id = obj.administrative.hasAdminPolicy
      item.source_id = obj.identification.sourceId
      item.collection_ids = [obj.structural&.isMemberOf].compact
      item.catkey = catkey_for(obj)
      item.label = truncate_label(obj.label)

      item.descMetadata.mods_title = obj.description.title.first.value

      add_tags(item, obj)
      change_access(item, obj.access.access)
      item.rightsMetadata.copyright = obj.access.copyright if obj.access.copyright
      item.rightsMetadata.use_statement = obj.access.useAndReproductionStatement if obj.access.useAndReproductionStatement
      create_embargo(item, obj.access.embargo) if obj.access.embargo
      item.contentMetadata.content = ContentMetadataGenerator.generate(druid: item.pid, object: obj) if obj&.structural&.contains

      add_identity_metadata(obj, item, 'item')
    end
    # rubocop:enable Metrics/AbcSize

    def validate(obj)
      if obj.is_a?(Cocina::Models::DRO)
        validator = ValidateDarkService.new(obj)
        raise Dor::ParameterError, "Not all files have dark access and/or are unshelved when item access is dark: #{validator.invalid_filenames}" unless validator.valid?
      end

      raise Dor::ParameterError, "Identifer on the query and in the body don't match" if item.pid != obj.externalIdentifier

      # Validate APO exists (this raises an error if it doesn't)
      Dor.find(obj.administrative.hasAdminPolicy)
    end

    # TODO: duplicate from ObjectCreator
    def catkey_for(obj)
      obj.identification&.catalogLinks&.find { |l| l.catalog == 'symphony' }&.catalogRecordId
    end

    # TODO: duplicate from ObjectCreator
    def create_embargo(item, embargo)
      EmbargoService.create(item: item,
                            release_date: embargo.releaseDate,
                            access: embargo.access,
                            use_and_reproduction_statement: embargo.useAndReproductionStatement)
    end

    # TODO: duplicate from ObjectCreator
    def add_tags(item, obj)
      tags = [content_type_tag(obj.type, obj.structural&.hasMemberOrders&.first&.viewingDirection)]
      tags << "Project : #{obj.administrative.partOfProject}" if obj.administrative.partOfProject
      AdministrativeTags.create(item: item, tags: tags, replace: true)
    end

    # TODO: duplicate from ObjectCreator
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

    # TODO: duplicate from ObjectCreator
    def change_access(item, access)
      raise 'location-based access not implemented' if access == 'location-based'

      # See https://github.com/sul-dlss/dor-services/blob/master/lib/dor/datastreams/rights_metadata_ds.rb
      rights_type = access == 'citation-only' ? 'none' : access
      Dor::RightsMetadataDS.upd_rights_xml_for_rights_type(item.rightsMetadata.ng_xml, rights_type)
      item.rightsMetadata.ng_xml_will_change!
    end

    # TODO: duplicate from ObjectCreator
    def add_identity_metadata(obj, item, object_type)
      item.objectId = item.pid
      item.objectCreator = 'DOR'
      # May have already been set when setting descriptive metadata.
      item.objectLabel = obj.label if item.objectLabel.empty?
      item.objectType = object_type
      # Not currently mapping other ids.
    end

    # TODO: duplicate from ObjectCreator
    def truncate_label(label)
      label.length > 254 ? label[0, 254] : label
    end
  end
end

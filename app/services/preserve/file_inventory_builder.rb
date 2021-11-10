# frozen_string_literal: true

module Preserve
  # This creates a Moab::FileInventory from the contentMetadata.xml
  class FileInventoryBuilder
    # @param [Pathname] metadata_dir The location of the the object's metadata files
    # @param [String] druid The object identifier
    # @param [Integer] version_id The version number
    # @return [Moab::FileInventory] Generate and return a version inventory for the object
    def self.build(metadata_dir:, druid:, version_id:)
      new(metadata_dir: metadata_dir,
          druid: druid,
          version_id: version_id).build
    end

    def initialize(metadata_dir:, druid:, version_id:)
      @metadata_dir = metadata_dir
      @druid = druid
      @version_id = version_id
    end

    def build
      content_inventory.tap do |version_inventory|
        version_inventory.groups << metadata_file_group
      end
    end

    attr_reader :metadata_dir, :druid, :version_id

    # @return [Moab::FileInventory] Parse the contentMetadata
    #   and generate a new version inventory object containing a content group
    def content_inventory
      if content_metadata
        Stanford::ContentInventory.new.inventory_from_cm(content_metadata, druid, 'preserve', version_id)
      else
        Moab::FileInventory.new(type: 'version', digital_object_id: druid, version_id: version_id)
      end
    end

    # @return [String] Return the contents of the contentMetadata.xml file from the content directory
    def content_metadata
      @content_metadata ||= (content_metadata_pathname.read if content_metadata_pathname.exist?)
    end

    def content_metadata_pathname
      @content_metadata_pathname ||= metadata_dir.join('contentMetadata.xml')
    end

    # @return [Moab::FileGroup] Traverse the metadata directory and generate a metadata group
    def metadata_file_group
      Moab::FileGroup.new(group_id: 'metadata').group_from_directory(metadata_dir)
    end
  end
end

# frozen_string_literal: true

# Push file changes for shelve-able files into stacks
class ShelvingService
  class ConfigurationError < RuntimeError; end
  class ShelvingError < StandardError; end

  def self.shelve(cocina_object)
    new(cocina_object).shelve
  end

  def initialize(cocina_object)
    raise ConfigurationError, 'Missing configuration Settings.stacks.local_workspace_root' if Settings.stacks.local_workspace_root.nil?
    raise ShelvingService::ShelvingError, 'Missing structural' if cocina_object.structural.nil?

    @cocina_object = cocina_object
    @druid = cocina_object.externalIdentifier
  end

  def shelve
    # determine the location of the object's files in the stacks area
    stacks_druid = DruidTools::StacksDruid.new(druid, stacks_location)
    stacks_object_pathname = Pathname(stacks_druid.path)
    # determine the location of the object's content files in the workspace area
    workspace_druid = DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)

    preserve_diff = content_diff('preserve')
    shelve_diff = content_diff('shelve')

    workspace_content_pathname = Pathname(workspace_druid.content_dir(true))
    ShelvableFilesStager.stage(druid, preserve_diff, shelve_diff, workspace_content_pathname)

    # workspace_content_pathname = workspace_content_dir(shelve_diff, workspace_druid)
    # delete, rename, or copy files to the stacks area
    DigitalStacksService.remove_from_stacks(stacks_object_pathname, shelve_diff)
    DigitalStacksService.rename_in_stacks(stacks_object_pathname, shelve_diff)
    DigitalStacksService.shelve_to_stacks(workspace_content_pathname, stacks_object_pathname, shelve_diff)
  end

  private

  attr_reader :cocina_object, :druid

  # retrieve the differences between the current contentMetadata and the previously ingested version
  # (filtering to select only the files that should be shelved or preserved to stacks, depending on param passed)
  # @return Moab::FileGroupDifference
  # @param [String] subset: 'shelve', 'preserve', 'publish', or 'all' .... filters file diffs
  # @raise [ShelvingService::ShelvingError] if something went wrong.
  def content_diff(subset)
    new_inventory = Stanford::ContentInventory.new.inventory_from_cm(content_metadata, druid, subset)
    inventory_diff = Moab::FileInventoryDifference.new.compare(base_inventory(subset), new_inventory)
    inventory_diff.group_difference('content')
  rescue StandardError => e
    raise ShelvingService::ShelvingError, e
  end

  def base_inventory(subset)
    cm_from_pres = Preservation::Client.objects.metadata(druid:, filepath: 'contentMetadata.xml')
    Stanford::ContentInventory.new.inventory_from_cm(cm_from_pres, druid, subset)
  rescue Preservation::Client::NotFoundError
    # Create a skeletal FileInventory object, containing no file entries
    storage_object = Moab::StorageObject.new(druid, 'dummy')
    base_version = Moab::StorageObjectVersion.new(storage_object, 0)
    base_version.file_inventory('version')
  end

  def stacks_location
    # Currently the best know way to identify objects like this is to see if the wasCrawlPreassemblyWF workflow is present.
    # If this condition is met, then shelf to /web-archiving-stacks/data/collections/<collection_id>, where collection_id is the unnamespaced druid of the (first) collection.
    return was_stack_location if was?

    Settings.stacks.local_stacks_root
  end

  def was?
    workflow_client.workflows(druid).include?('wasCrawlPreassemblyWF')
  end

  def was_stack_location
    collection_druid = cocina_object.structural&.isMemberOf&.first

    raise ShelvingService::ShelvingError, 'Web archive object missing collection' unless collection_druid

    "/web-archiving-stacks/data/collections/#{collection_druid.delete_prefix('druid:')}"
  end

  def content_metadata
    @content_metadata ||= Cocina::ToXml::ContentMetadataGenerator.generate(druid:, structural: cocina_object.structural, type: cocina_object.type)
  end

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end

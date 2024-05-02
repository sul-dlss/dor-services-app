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

    # In stage, we consistently get Errno::EEXIST.
    # The theory is that this is a sync issue with the underlying filesystem.
    # This addresses the issue by retrying the operation; upon retry, the directory should be found
    # to exist and the operation should succeed properly.
    workspace_content_pathname = nil
    begin
      workspace_content_pathname = Pathname(workspace_druid.content_dir(true))
    rescue Errno::EEXIST
      retry
    end

    ShelvableFilesStager.stage(druid, preserve_diff, shelve_diff, workspace_content_pathname)

    # workspace_content_pathname = workspace_content_dir(shelve_diff, workspace_druid)
    # delete, rename, or copy files to the stacks area
    DigitalStacksService.remove_from_stacks(stacks_object_pathname, shelve_diff)
    DigitalStacksService.rename_in_stacks(stacks_object_pathname, shelve_diff)
    DigitalStacksService.shelve_to_stacks(workspace_content_pathname, stacks_object_pathname, shelve_diff)
  end

  private

  attr_reader :cocina_object, :druid

  # retrieve the differences between the SDR object cocina derived contentMetadata
  # (i.e. the version currently accessioned, could be a new object or a new version of an existing object)
  # and the previously ingested version's contentMetadata (if it exists, i.e. could be empty for a new object)
  # We also filter to select only the files that should be shelved or preserved to stacks, depending on param passed
  # Note: the `content_diff` implementation below mostly re-implements `Stanford::StorageServices.compare_cm_to_version`
  # in the `moab-versioning` gem, but in a way that uses XML retrieved via preservation-client instead of reading the
  # XML from disk.  This allows dor-services-app to perform the potentially time expensive diff without requiring
  # access to preservation disk mounts.
  # See https://github.com/sul-dlss/dor-services-app/pull/4492 and https://github.com/sul-dlss/dor-services-app/issues/4359
  # @return Moab::FileGroupDifference
  # @param [String] subset: 'shelve', 'preserve', 'publish', or 'all' .... filters file diffs
  # @raise [ShelvingService::ShelvingError] if something went wrong.
  def content_diff(subset)
    new_inventory = Stanford::ContentInventory.new.inventory_from_cm(content_metadata, druid, subset)
    inventory_diff = Moab::FileInventoryDifference.new.compare(base_inventory(subset), new_inventory)
    metadata_diff = inventory_diff.group_difference('metadata')
    inventory_diff.group_differences.delete(metadata_diff) if metadata_diff
    inventory_diff.group_difference('content')
  rescue StandardError => e
    raise ShelvingService::ShelvingError, e
  end

  def base_inventory(subset)
    base_version = Preservation::Client.objects.current_version(druid)
    cm_from_pres = Preservation::Client.objects.metadata(druid:, filepath: 'contentMetadata.xml')
    Stanford::ContentInventory.new.inventory_from_cm(cm_from_pres, druid, subset, base_version)
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

  # The SDR object's content metadata before being sent to preservation,
  # i.e. either initial version if not yet accessioned, or version in the process of being accessioned
  # Generated by converting from cocina
  def content_metadata
    @content_metadata ||= Cocina::ToXml::ContentMetadataGenerator.generate(druid:, structural: cocina_object.structural, type: cocina_object.type)
  end

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end

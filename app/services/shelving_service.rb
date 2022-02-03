# frozen_string_literal: true

# Push file changes for shelve-able files into stacks
class ShelvingService
  class ConfigurationError < RuntimeError; end

  def self.shelve(cocina_object)
    new(cocina_object).shelve
  end

  def initialize(cocina_object)
    raise ConfigurationError, 'Missing configuration Dor::Config.stacks.local_workspace_root' if Dor::Config.stacks.local_workspace_root.nil?
    raise Dor::Exception, 'Missing structural' if cocina_object.structural.nil?

    @cocina_object = cocina_object
  end

  def shelve
    # determine the location of the object's files in the stacks area
    stacks_druid = DruidTools::StacksDruid.new(cocina_object.externalIdentifier, stacks_location)
    stacks_object_pathname = Pathname(stacks_druid.path)
    # determine the location of the object's content files in the workspace area
    workspace_druid = DruidTools::Druid.new(cocina_object.externalIdentifier, Dor::Config.stacks.local_workspace_root)

    workspace_content_pathname = Pathname(workspace_druid.content_dir(true))
    ShelvableFilesStager.stage(cocina_object.externalIdentifier, content_metadata, shelve_diff, workspace_content_pathname)

    # workspace_content_pathname = workspace_content_dir(shelve_diff, workspace_druid)
    # delete, rename, or copy files to the stacks area
    DigitalStacksService.remove_from_stacks(stacks_object_pathname, shelve_diff)
    DigitalStacksService.rename_in_stacks(stacks_object_pathname, shelve_diff)
    DigitalStacksService.shelve_to_stacks(workspace_content_pathname, stacks_object_pathname, shelve_diff)
  end

  private

  attr_reader :cocina_object

  # retrieve the differences between the current contentMetadata and the previously ingested version
  # (filtering to select only the files that should be shelved to stacks)
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  # @raise [ConfigurationError] if missing local workspace root.
  # @raise [Dor::Exception] if something went wrong.
  def shelve_diff
    @shelve_diff ||= Preservation::Client.objects.shelve_content_diff(druid: cocina_object.externalIdentifier, content_metadata: content_metadata)
  rescue Preservation::Client::Error => e
    raise Dor::Exception, e
  end

  def stacks_location
    # Currently the best know way to identify objects like this is to see if the wasCrawlPreassemblyWF workflow is present.
    # If this condition is met, then shelf to /web-archiving-stacks/data/collections/<collection_id>, where collection_id is the unnamespaced druid of the (first) collection.
    return was_stack_location if was?

    Dor::Config.stacks.local_stacks_root
  end

  def was?
    workflow_client.workflows(cocina_object.externalIdentifier).include?('wasCrawlPreassemblyWF')
  end

  def was_stack_location
    collection_druid = cocina_object.structural&.isMemberOf&.first

    raise Dor::Exception, 'Web archive object missing collection' unless collection_druid

    "/web-archiving-stacks/data/collections/#{collection_druid.delete_prefix('druid:')}"
  end

  def content_metadata
    @content_metadata ||= Cocina::ToFedora::ContentMetadataGenerator.generate(druid: cocina_object.externalIdentifier, structural: cocina_object.structural, type: cocina_object.type)
  end

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end

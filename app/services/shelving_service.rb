# frozen_string_literal: true

# Push file changes for shelve-able files into stacks
class ShelvingService
  class ConfigurationError < RuntimeError; end

  def self.shelve(work)
    new(work).shelve
  end

  def initialize(work)
    raise ConfigurationError, 'Missing configuration Dor::Config.stacks.local_workspace_root' if Dor::Config.stacks.local_workspace_root.nil?
    raise Dor::Exception, 'Missing contentMetadata datastream' if work.contentMetadata.nil?

    @work = work
    @content_metadata = work.contentMetadata.content
  end

  def shelve
    # determine the location of the object's files in the stacks area
    stacks_druid = DruidTools::StacksDruid.new(work.id, stacks_location)
    stacks_object_pathname = Pathname(stacks_druid.path)
    # determine the location of the object's content files in the workspace area
    workspace_druid = DruidTools::Druid.new(work.id, Dor::Config.stacks.local_workspace_root)

    workspace_content_pathname = Pathname(workspace_druid.content_dir(true))
    ShelvableFilesStager.stage(work.id, content_metadata, shelve_diff, workspace_content_pathname)

    # workspace_content_pathname = workspace_content_dir(shelve_diff, workspace_druid)
    # delete, rename, or copy files to the stacks area
    DigitalStacksService.remove_from_stacks(stacks_object_pathname, shelve_diff)
    DigitalStacksService.rename_in_stacks(stacks_object_pathname, shelve_diff)
    DigitalStacksService.shelve_to_stacks(workspace_content_pathname, stacks_object_pathname, shelve_diff)
  end

  private

  attr_reader :work, :content_metadata

  # retrieve the differences between the current contentMetadata and the previously ingested version
  # (filtering to select only the files that should be shelved to stacks)
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  # @raise [ConfigurationError] if missing local workspace root.
  # @raise [Dor::Exception] if something went wrong.
  def shelve_diff
    @shelve_diff ||= Preservation::Client.objects.shelve_content_diff(druid: work.pid, content_metadata: content_metadata)
  rescue Preservation::Client::Error => e
    raise Dor::Exception, e
  end

  # get the stack location based on the contentMetadata stacks attribute
  # or using the default value from the config file if it doesn't exist
  def stacks_location
    return Dor::Config.stacks.local_stacks_root if work.contentMetadata.stacks.blank?

    location = work.contentMetadata.stacks[0]
    return location if location.start_with? '/' # Absolute stacks path

    raise "stacks attribute for item: #{work.id} contentMetadata should start with /. The current value is #{location}"
  end
end

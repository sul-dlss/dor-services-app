# frozen_string_literal: true

require 'pathname'

# Remove all traces of the object's data files from the workspace and export areas
class CleanupService
  # @param [String] druid The identifier for the object for which we will stop accessioning
  # @param [boolean] dryrun if true, will just display output but not perform actions
  def self.stop_accessioning(druid, dryrun: false)
    # This will raise an exception if an invalid format (or no) druid is passed in
    druid_obj = DruidTools::Druid.new(druid)

    # Returns the druid with prefix even if not passed in with a prefix, e.g. druid:ab123bc4567
    druid = druid_obj.druid

    # Verify druid exists: this will raise an exception if the druid is not found
    object = CocinaObjectStore.find(druid)

    $stdout.puts '*** DRY RUN - NO ACTIONS WILL BE PERFORMED' if dryrun
    $stdout.puts "...object found is an item: version #{object.version}"

    # Verify the current version has not made it to preservation by checking if it is openable:
    # if it is, then it must have been sent to preservation and therefore we must stop.
    raise "v#{object.version} of the object has already been sent to preservation: cannot proceed" if VersionService.can_open?(druid:, version: object.version)

    # If `preservationIngestWF#complete-ingest` exists and is not completed, then a step in this workflow is likely in error
    # (ie. preservation got part way and then failed) and we should stop, since extra remediation may be needed
    ingest_complete = WorkflowClientFactory.build.workflow_status(druid:, workflow: 'preservationIngestWF', process: 'complete-ingest')
    raise "v#{object.version} of the object has preservationIngestWF#complete-ingest not completed: cannot proceed" if ingest_complete.present? && ingest_complete != 'completed'

    $stdout.puts "...v#{object.version} of the object has not been sent to preservation"

    # backup folders
    $stdout.puts '...backing up content folders'
    backup_content_by_druid(druid) unless dryrun

    # delete workspace folders
    $stdout.puts '...deleting content folders'
    cleanup_by_druid(druid) unless dryrun

    # Delete workflows for the current object version
    $stdout.puts '...deleting workflows'
    delete_accessioning_workflows(druid, object.version) unless dryrun

    # Let user know we are done
    $stdout.puts "...accessioning stopped complete for #{druid}"
  end

  # @param [String] druid The identifier for the object whose data is to be removed
  def self.cleanup_by_druid(druid)
    cleanup_workspace_content(druid, Settings.cleanup.local_workspace_root)
    cleanup_workspace_content(druid, Settings.cleanup.local_assembly_root)
    cleanup_export(druid)
  end

  # @param [String] druid The identifier for the object whose data is to be backed up
  def self.backup_content_by_druid(druid)
    backup_content(druid, Settings.cleanup.local_workspace_root, Settings.cleanup.local_backup_path)
    backup_content(druid, Settings.cleanup.local_assembly_root, Settings.cleanup.local_backup_path)
    backup_content(druid, Settings.cleanup.local_export_home, Settings.cleanup.local_backup_path)
  end

  # @param [String] druid The identifier for the object whose accessioning workflows should be deleted
  # @param [String] version The object version to delete workflows for
  def self.delete_accessioning_workflows(druid, version)
    %w[accessionWF assemblyWF versioningWF].each do |workflow|
      WorkflowClientFactory.build.delete_workflow(druid:, workflow:, version:)
    end
  end

  # @param [String] druid The identifier for the object whose data is to be removed
  # @param [String] base The base directory to delete from
  # @return [void] remove the object's data files from the workspace area
  # @raise [Errno::ENOTEMPTY] if the directory is not empty
  def self.cleanup_workspace_content(druid, base)
    PruneService.new(druid: DruidTools::Druid.new(druid, base)).prune!
  end
  private_class_method :cleanup_workspace_content

  # Backup specified workspace content folder (e.g. /dor/workspace) if they exist
  # Content is backed up to a base druid folder and then subfolders by workspace (allowing for multiple to exist)
  # e.g. /dor/workspace/ab/123/bc/4567/ab1234567 --> /dor/staging/stopped/ab123bc4567/workspace/content /metadata
  #      /dor/assembly/ab/123/bc/4567/ab1234567 ---> /dor/staging/stopped/ab123bc4567/assembly
  # @param [String] druid The identifier for the object whose data is to be backed up
  # @param [String] base The base directory path to backup from
  # @return [String] backup_path The directory to backup to
  def self.backup_content(druid, base, backup_path)
    content_path = DruidTools::Druid.new(druid, base) # e.g. /dor/workspace/ab/123/bc/4567/ab1234567

    return unless File.directory?(content_path.path)

    base_backup_path = File.join(backup_path, content_path.id) # e.g. /dor/staging/stopped/ab123bc4567
    specific_backup_path = File.join(base_backup_path, File.basename(base)) # e.g. /dor/staging/stopped/ab123bc4567/workspace

    FileUtils.mkdir_p(base_backup_path)
    FileUtils.cp_r(content_path.path, specific_backup_path)
  end
  private_class_method :backup_content

  # @param [String] druid The identifier for the object whose data is to be removed
  # @return [void] remove copy of the data that was exported to preservation core
  def self.cleanup_export(druid)
    id = druid.delete_prefix('druid:')
    bag_dir = File.join(Settings.cleanup.local_export_home, id)
    FileUtils.rm_rf(bag_dir)
    tarfile = "#{bag_dir}.tar"
    FileUtils.rm_f(tarfile)
  end
  private_class_method :cleanup_export
end

# frozen_string_literal: true

require 'pathname'

# Remove all traces of the object's data files from the workspace and export areas
class CleanupService
  def self.stop_accessioning(druid, dryrun: false)
    new(druid:).stop_accessioning(dryrun:)
  end

  def self.cleanup_by_druid(druid)
    new(druid:).cleanup_by_druid
  end

  def self.backup_content_by_druid(druid)
    new(druid:).backup_content_by_druid
  end

  def self.delete_accessioning_workflows(druid, version)
    new(druid:).delete_accessioning_workflows(version:)
  end

  # @param [String] druid The identifier for the object
  def initialize(druid:)
    # This will raise an exception if an invalid format (or no) druid is passed in
    druid_obj = DruidTools::Druid.new(druid)

    # Returns the druid with prefix even if not passed in with a prefix, e.g. druid:ab123bc4567
    @druid = druid_obj.druid
  end

  # @param [boolean] dryrun if true, will just display output but not perform actions
  def stop_accessioning(dryrun: false)
    # Verify druid exists and can be stopped
    raise "Object #{druid} not found in repository" unless repository_object

    @version = repository_object.head_version.version

    $stdout.puts '*** DRY RUN - NO ACTIONS WILL BE PERFORMED' if dryrun
    $stdout.puts "...object found is an item: version #{version}"

    $stdout.puts "...v#{version} of the object has not been sent to preservation"

    if repository_object.can_discard_open_version?
      $stdout.puts "Discarding head version of object #{druid}"
      repository_object.discard_open_version! unless dryrun
    else
      $stdout.puts "Head version of object #{druid} cannot be discarded"
      if repository_object.closed?
        $stdout.puts "Reopening object #{druid}"
        repository_object.reopen! unless dryrun
      end
    end

    # backup folders
    $stdout.puts '...backing up content folders'
    backup_content_by_druid unless dryrun

    # delete workspace folders
    $stdout.puts '...deleting content folders'
    cleanup_by_druid unless dryrun

    # Delete workflows for the current object version
    $stdout.puts '...deleting workflows'
    delete_accessioning_workflows(version:) unless dryrun

    # Let user know we are done
    $stdout.puts "...accessioning stopped complete for #{druid}"
  end

  def cleanup_by_druid
    cleanup_workspace_content(Settings.cleanup.local_workspace_root)
    cleanup_workspace_content(Settings.cleanup.local_assembly_root)
    cleanup_export
  end

  def backup_content_by_druid
    backup_content(Settings.cleanup.local_workspace_root, Settings.cleanup.local_backup_path)
    backup_content(Settings.cleanup.local_assembly_root, Settings.cleanup.local_backup_path)
    backup_content(Settings.cleanup.local_export_home, Settings.cleanup.local_backup_path)
  end

  # @param [String] version The object version to delete workflows for
  def delete_accessioning_workflows(version:)
    %w[accessionWF assemblyWF versioningWF].each do |workflow|
      WorkflowClientFactory.build.delete_workflow(druid:, workflow:, version:)
    end
  end

  private

  attr_reader :druid, :version

  def repository_object
    @repository_object ||= RepositoryObject.find_by(external_identifier: druid)
  end

  # @param [String] base The base directory to delete from
  # @return [void] remove the object's data files from the workspace area
  # @raise [Errno::ENOTEMPTY] if the directory is not empty
  def cleanup_workspace_content(base)
    PruneService.new(druid: DruidTools::Druid.new(druid, base)).prune!
  end

  # Backup specified workspace content folder (e.g. /dor/workspace) if they exist
  # Content is backed up to a base druid folder and then subfolders by workspace (allowing for multiple to exist)
  # e.g. /dor/workspace/ab/123/bc/4567/ab1234567 --> /dor/staging/stopped/ab123bc4567/workspace/content /metadata
  #      /dor/assembly/ab/123/bc/4567/ab1234567 ---> /dor/staging/stopped/ab123bc4567/assembly
  # @param [String] base The base directory path to backup from
  # @return [String] backup_path The directory to backup to
  def backup_content(base, backup_path)
    content_path = DruidTools::Druid.new(druid, base) # e.g. /dor/workspace/ab/123/bc/4567/ab1234567

    return unless File.directory?(content_path.path)

    base_backup_path = File.join(backup_path, content_path.id) # e.g. /dor/staging/stopped/ab123bc4567
    specific_backup_path = File.join(base_backup_path, File.basename(base)) # e.g. /dor/staging/stopped/ab123bc4567/workspace

    FileUtils.mkdir_p(base_backup_path)
    FileUtils.cp_r(content_path.path, specific_backup_path)
  end

  # @return [void] remove copy of the data that was exported to preservation core
  def cleanup_export
    id = druid.delete_prefix('druid:')
    bag_dir = File.join(Settings.cleanup.local_export_home, id)
    FileUtils.rm_rf(bag_dir)
    tarfile = "#{bag_dir}.tar"
    FileUtils.rm_f(tarfile)
  end
end

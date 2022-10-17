# frozen_string_literal: true

require 'pathname'

# Remove all traces of the object's data files from the workspace and export areas
class CleanupService
  def self.cleanup_by_druid(druid)
    cleanup_workspace_content(druid, Settings.cleanup.local_workspace_root)
    cleanup_workspace_content(druid, Settings.cleanup.local_assembly_root)
    cleanup_export(druid)
  end

  # @param [String] druid The identifier for the object whose data is to be removed
  # @param [String] base The base directory to delete from
  # @return [void] remove the object's data files from the workspace area
  # @raise [Errno::ENOTEMPTY] if the directory is not empty
  def self.cleanup_workspace_content(druid, base)
    PruneService.new(druid: DruidTools::Druid.new(druid, base)).prune!
  end
  private_class_method :cleanup_workspace_content

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

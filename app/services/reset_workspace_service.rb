# frozen_string_literal: true

# Rename the druid trees  at the end of the accessionWF in order to be cleaned/deleted later.
class ResetWorkspaceService
  class DirectoryAlreadyExists < StandardError; end
  class BagAlreadyExists < StandardError; end

  # @raise [DirectoryAlreadyExists] if the archived directory already exists
  # @raise [BagAlreadyExists] if the bag for this version already exists
  # @raise [Errno::ENOENT] if the directory doesn't exist
  def self.reset(druid:, version:)
    reset_workspace_druid_tree(druid: druid, version: version, workspace_root: Dor::Config.stacks.local_workspace_root)
    remove_export_bag(druid: druid, export_root: Settings.sdr.local_export_home)
  end

  # @raises [Errno::ENOENT] if the directory doesn't exist
  def self.reset_workspace_druid_tree(druid:, version:, workspace_root:)
    druid_tree_path = DruidTools::Druid.new(druid, workspace_root).pathname.to_s

    raise DirectoryAlreadyExists, "The archived directory #{druid_tree_path}_v#{version} already existed." if File.exist?("#{druid_tree_path}_v#{version}")

    # If the file doesn't exist it is a truncated tree where we shouldn't do anything
    return unless File.exist?(druid_tree_path)

    FileUtils.mv(druid_tree_path, "#{druid_tree_path}_v#{version}")
  end

  # Removes the export directory. This should be called after the bag has been transfered to preservation
  def self.remove_export_bag(druid:, export_root:)
    id = druid.split(':').last
    bag_dir = File.join(export_root, id)

    FileUtils.rm_r(bag_dir) if File.exist?(bag_dir)

    FileUtils.rm("#{bag_dir}.tar") if File.exist?("#{bag_dir}.tar")
  end
end

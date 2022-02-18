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
    reset_export_bag(druid: druid, version: version, export_root: Settings.sdr.local_export_home)
  end

  # @raises [Errno::ENOENT] if the directory doesn't exist
  def self.reset_workspace_druid_tree(druid:, version:, workspace_root:)
    druid_tree_path = DruidTools::Druid.new(druid, workspace_root).pathname.to_s

    if File.exist?("#{druid_tree_path}_v#{version}")
      raise DirectoryAlreadyExists,
            "The archived directory #{druid_tree_path}_v#{version} already existed."
    end

    # If the file doesn't exist it is a truncated tree where we shouldn't do anything
    return unless File.exist?(druid_tree_path)

    FileUtils.mv(druid_tree_path, "#{druid_tree_path}_v#{version}")
  end

  def self.reset_export_bag(druid:, version:, export_root:)
    id = druid.split(':').last
    bag_dir = File.join(export_root, id)

    if File.exist?("#{bag_dir}_v#{version}")
      raise BagAlreadyExists,
            "The archived bag #{bag_dir}_v#{version} already existed."
    end

    FileUtils.mv(bag_dir, "#{bag_dir}_v#{version}") if File.exist?(bag_dir)

    FileUtils.mv("#{bag_dir}.tar", "#{bag_dir}_v#{version}.tar") if File.exist?("#{bag_dir}.tar")
  end
end

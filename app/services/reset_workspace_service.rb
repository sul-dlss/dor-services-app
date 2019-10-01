# frozen_string_literal: true

# Rename the druid trees  at the end of the accessionWF in order to be cleaned/deleted later.
class ResetWorkspaceService
  def self.reset(druid:, version:)
    reset_workspace_druid_tree(druid: druid, version: version, workspace_root: Dor::Config.stacks.local_workspace_root)
    reset_export_bag(druid: druid, version: version, export_root: Settings.sdr.local_export_home)
  end

  def self.reset_workspace_druid_tree(druid:, version:, workspace_root:)
    druid_tree_path = DruidTools::Druid.new(druid, workspace_root).pathname.to_s

    raise "The archived directory #{druid_tree_path}_v#{version} already existed." if File.exist?("#{druid_tree_path}_v#{version}")

    # If the file doesn't exist it is a truncated tree where we shouldn't do anything
    return unless File.exist?(druid_tree_path)

    FileUtils.mv(druid_tree_path, "#{druid_tree_path}_v#{version}")
  end

  def self.reset_export_bag(druid:, version:, export_root:)
    id = druid.split(':').last
    bag_dir = File.join(export_root, id)

    raise "The archived bag #{bag_dir}_v#{version} already existed." if File.exist?("#{bag_dir}_v#{version}")

    FileUtils.mv(bag_dir, "#{bag_dir}_v#{version}") if File.exist?(bag_dir)

    FileUtils.mv("#{bag_dir}.tar", "#{bag_dir}_v#{version}.tar") if File.exist?("#{bag_dir}.tar")
  end
end

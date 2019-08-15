# frozen_string_literal: true

# Creates workspaces.  This replaces https://github.com/sul-dlss/dor-services/blob/master/lib/dor/models/concerns/assembleable.rb
class WorkspaceService
  # @param [Dor::Item] work the work to create the workspace for
  # @param [String, nil] source the path to create
  def self.create(work, source)
    druid = DruidTools::Druid.new(work.pid, Settings.stacks.local_workspace_root)
    source ? mkdir_with_final_link(druid: druid, source: source) : druid.mkdir
  end

  def self.mkdir_with_final_link(druid:, source:)
    new_path = druid.path
    raise DruidTools::DifferentContentExistsError, "Unable to create link, directory already exists: #{new_path}" if File.directory?(new_path) && !File.symlink?(new_path)

    real_path = File.expand_path('..', new_path)
    FileUtils.mkdir_p(real_path)
    FileUtils.ln_s(source, new_path, force: true)
  end
  private_class_method :mkdir_with_final_link
end

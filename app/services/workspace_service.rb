# frozen_string_literal: true

# Creates workspaces.  This replaces https://github.com/sul-dlss/dor-services/blob/main/lib/dor/models/concerns/assembleable.rb
class WorkspaceService
  # @param [String] druid the identifier of the item to create the workspace for
  # @param [String, nil] source the path to create
  def self.create(druid, source)
    druid_obj = DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)
    return mkdir_with_final_link(druid_obj:, source:) if source

    Honeybadger.notify('Source was not provided to WorkspaceService.create. ' \
                       "I'm pretty sure that source is always supplied and ought to be required")
    druid_obj.mkdir
  end

  def self.mkdir_with_final_link(druid_obj:, source:)
    new_path = druid_obj.path
    raise DruidTools::DifferentContentExistsError, "Unable to create link, directory already exists: #{new_path}" if File.directory?(new_path) && !File.symlink?(new_path)

    real_path = File.expand_path('..', new_path)
    FileUtils.mkdir_p(real_path)
    FileUtils.ln_s(source, new_path, force: true)
  end
  private_class_method :mkdir_with_final_link
end

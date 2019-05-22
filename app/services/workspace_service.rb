# frozen_string_literal: true

# Creates workspaces.  This replaces https://github.com/sul-dlss/dor-services/blob/master/lib/dor/models/concerns/assembleable.rb
class WorkspaceService
  # @param [Dor::Item] work the work to create the workspace for
  # @param [String] source the path to create
  def self.create(work, source)
    druid = DruidTools::Druid.new(work.pid, Settings.stacks.local_workspace_root)
    return druid.mkdir if source.nil?

    druid.mkdir_with_final_link(source)
  end
end

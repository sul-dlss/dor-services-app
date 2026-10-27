# frozen_string_literal: true

# Creates workspaces.  This replaces https://github.com/sul-dlss/dor-services/blob/main/lib/dor/models/concerns/assembleable.rb
class WorkspaceService
  # @param [String] druid the identifier of the item to create the workspace for
  # @param [Boolean] content whether to create the content directory (optional)
  # @param [Boolean] metadata whether to create the metadata directory (optional)
  # @return [String] the path to the created workspace
  def self.create(druid, content: false, metadata: false)
    druid_obj = DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)
    path = druid_obj.mkdir&.first # druid_obj.mkdir returns an array - we want the first entry
    druid_obj.content_dir if content # druid-tools will create the content/metadata directories if they don't exist
    druid_obj.metadata_dir if metadata
    path
  end
end

# frozen_string_literal: true

# Checks the workflow status for a given item and version and returns error information
class WorkflowErrorCheckingService
  # @param [Dor::Item] item - the Dor::Item to check
  # @param [String] version - the version of the item to check
  # @return [Array<String>] an array of error strings, or an empty array if no errors
  def self.check(item:, version:)
    new(item: item, version: version).check
  end

  attr_reader :item, :version

  # @param [Dor::Item] item - the Dor::Item to check
  # @param [String] version - the version of the item to check
  def initialize(item:, version:)
    @item = item
    @version = version
  end

  # @return [Array<String>] an array of error strings, or an empty array if no errors
  def check
    Dor::Config.workflow.client.workflow_routes.all_workflows(pid: item.id).errors_for(version: version)
  end
end

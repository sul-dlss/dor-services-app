# frozen_string_literal: true

# Service for interacting with workflow lifecycles.
class WorkflowLifecycleService
  def self.lifecycle_xml(...)
    new(...).lifecycle_xml
  end

  def self.milestone?(druid:, milestone_name:, version: nil, active_only: false)
    new(druid: druid, version: version, active_only: active_only).milestone?(milestone_name: milestone_name)
  end

  # @param [String] druid object id
  # @param [Number] version (nil) the version to query for
  # @param [Boolean] active_only if true, return only lifecycle steps for versions that have all processes complete
  def initialize(druid:, version: nil, active_only: false)
    @druid = druid
    @version = version
    @active_only = active_only
  end

  # @return [Nokogiri::XML::Document] the XML document representing the lifecycle of the object
  def lifecycle_xml
    workflow_client.query_lifecycle(druid, version: version, active_only: active_only)
  end

  # @param [String] milestone_name the name of the milestone
  # @return [Boolean] true if the object has the milestone
  def milestone?(milestone_name:)
    lifecycle_xml.at_xpath("//lifecycle/milestone[text() = '#{milestone_name}']").present?
  end

  private

  attr_reader :druid, :version, :active_only

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end

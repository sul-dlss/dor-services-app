# frozen_string_literal: true

# Service for interacting with workflow lifecycles.
class WorkflowLifecycleService
  def self.lifecycle_xml(...)
    new(...).lifecycle_xml
  end

  def self.milestone?(druid:, milestone_name:, version: nil, active_only: false)
    new(druid: druid, version: version, active_only: active_only).milestone?(milestone_name: milestone_name)
  end

  def self.milestones(...)
    new(...).milestones
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
    if Settings.enabled_features.local_wf
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.lifecycle(objectId: druid) do
          workflow_steps.each do |step|
            step.as_milestone(xml)
          end
        end
      end
      builder.doc
    else
      workflow_client.query_lifecycle(druid, version: version, active_only: active_only)
    end
  end

  # @param [String] milestone_name the name of the milestone
  # @return [Boolean] true if the object has the milestone
  def milestone?(milestone_name:)
    lifecycle_xml.at_xpath("//lifecycle/milestone[text() = '#{milestone_name}']").present?
  end

  # @return [Array<Hash>]
  def milestones
    lifecycle_xml.xpath('//lifecycle/milestone').collect do |node|
      { milestone: node.text, at: Time.zone.parse(node['date']), version: node['version'] }
    end
  end

  private

  attr_reader :druid, :version, :active_only

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end

  def workflow_steps
    steps = WorkflowStep.where(druid:)

    return steps.lifecycle.complete unless active_only

    # Active means that it's of the current version, and that all the steps in
    # the current version haven't been completed yet.
    steps = steps.for_version(version)
    return [] unless steps.incomplete.any?

    steps.lifecycle
  end
end

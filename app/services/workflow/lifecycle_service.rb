# frozen_string_literal: true

module Workflow
  # Service for interacting with workflow lifecycles.
  class LifecycleService
    def self.lifecycle_xml(...)
      new(...).lifecycle_xml
    end

    def self.milestone?(druid:, milestone_name:, version: nil)
      new(druid: druid, version: version).milestone?(milestone_name: milestone_name)
    end

    def self.milestones(...)
      new(...).milestones
    end

    # @return [Boolean] true if the object has previously been accessioned.
    def self.accessioned?(druid:)
      new(druid:).milestone?(milestone_name: 'accessioned')
    end

    # @param [String] druid object id
    # @param [Number] version (nil) the version to query for
    def initialize(druid:, version: nil)
      @druid = druid
      @version = version
    end

    # @return [Nokogiri::XML::Document] the XML document representing the lifecycle of the object
    def lifecycle_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.lifecycle(objectId: druid) do
          workflow_steps.each do |step|
            xml.milestone(step.lifecycle,
                          date: (step.completed_at || step.created_at).to_time.iso8601,
                          version: step.version)
          end
        end
      end
      builder.doc
    end

    # @param [String] milestone_name the name of the milestone
    # @return [Boolean] true if the object has the milestone
    def milestone?(milestone_name:)
      workflow_steps.any? { |step| step.lifecycle == milestone_name }
    end

    # @return [Array<Hash>]
    def milestones
      workflow_steps.map do |step|
        { milestone: step.lifecycle, at: step.completed_at || step.created_at, version: step.version.to_s }
      end
    end

    private

    attr_reader :druid, :version, :active_only

    def workflow_steps
      steps = WorkflowStep.where(druid:)
      steps = steps.for_version(version) if version.present?

      steps.lifecycle.complete
    end
  end
end

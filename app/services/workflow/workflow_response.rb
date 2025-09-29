# frozen_string_literal: true

module Workflow
  # Model for a workflow.
  # Equivalent to Dor::Services::Response::Workflow, but without the XML.
  class WorkflowResponse
    def initialize(druid:, workflow_name:, steps:)
      @steps = steps
      @druid = druid
      @workflow_name = workflow_name
    end

    attr_reader :druid, :workflow_name, :steps

    def pid
      druid
    end

    # Check if there are any processes for the provided version.
    # @param [Integer] version the version we are checking for.
    def active_for?(version:)
      versions.include?(version)
    end

    def error_count
      @error_count ||= steps_for_latest_version.count { |step| step.status == 'error' }
    end

    # Returns the process for the most recent version that matches the given name:
    def process_for_recent_version(name:)
      step = steps_for_latest_version.find { |step| step.process == name }
      return unless step

      ProcessResponse.new(step:)
    end

    delegate :empty?, to: :steps

    # Check if all processes are skipped or complete for the provided version.
    # @param [Integer] version the version we are checking for.
    def complete_for?(version:)
      incomplete_processes_for(version: version).empty?
    end

    def complete?
      complete_for?(version: latest_version)
    end

    def incomplete_processes_for(version:)
      steps_for_version(version: version).filter_map do |step|
        next if %w[skipped completed].include?(step.status)

        ProcessResponse.new(step:)
      end
    end

    def incomplete_processes
      incomplete_processes_for(version: latest_version)
    end

    private

    def versions
      @versions ||= steps_by_version.keys
    end

    def latest_version
      @latest_version ||= versions.max
    end

    def steps_for_latest_version
      steps_for_version(version: latest_version)
    end

    def steps_for_version(version:)
      steps_by_version[version] || []
    end

    def steps_by_version
      @steps_by_version ||= {}.tap do |hash|
        steps.each do |step|
          hash[step.version] ||= []
          hash[step.version] << step
        end
      end
    end
  end
end

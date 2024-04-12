# frozen_string_literal: true

# Queries the workflow state of an object.
# This is primarily intended to support versioning.
class WorkflowStateService
  def self.accessioning?(...)
    new(...).accessioning?
  end

  def self.active_version_wf?(...)
    new(...).active_version_wf?
  end

  def initialize(druid:, version:)
    @druid = druid
    @version = version
  end

  # Checks if the latest version has any assembly workflows with incomplete steps.
  # @return [Boolean] true if object is currently being assembled
  def assembling?
    # Omitting the last step for these workflows since the last step is closing the version.
    # Without this the version can't be closed.
    # The exception is GIS workflows.
    # gisAssemblyWF kicks off the gisDeliveryWF, the last step of which is closing the version.
    # For these purposes, we'll be considering gisDeliveryWF as an assemblyWF.
    active_workflow_except_step?(workflow: 'assemblyWF', process: 'accessioning-initiate') ||
      active_workflow_except_step?(workflow: 'wasCrawlPreassemblyWF', process: 'end-was-crawl-preassembly') ||
      active_workflow_except_step?(workflow: 'wasSeedPreassemblyWF', process: 'end-was-seed-preassembly') ||
      active_workflow_except_step?(workflow: 'gisDeliveryWF', process: 'start-accession-workflow') ||
      active_workflow?(workflow: 'gisAssemblyWF')
  end

  def open?
    # If version 1, true if not in accessioning or has not been accessioned.
    return !accessioning? && !accessioned? if version == 1

    # Otherwise, is there an active versionWF?
    active_workflow?(workflow: 'versioningWF')
  end

  # The following methods were extracted from VersionService.
  # As such, they may not represent the current best practice for determining workflow state
  # and will probably be subject to further refactoring or removal.

  # Checks if the active (latest) version has any incomplete workflow steps and there is an accessionWF (known by the presence of a submitted milestone).
  # If so we don't want to start another acceession workflow.  This is also true if a preservationAuditWF has returned an error, so that no further
  # accessioning can take place until that is resolved.
  # @return [Boolean] true if object is currently being accessioned or is failing an audit
  def accessioning?
    return true if workflow_client.active_lifecycle(druid:, milestone_name: 'submitted', version: version.to_s)

    false
  end

  def active_version_wf?
    return true if workflow_client.active_lifecycle(druid:, milestone_name: 'opened', version: version.to_s)

    # Note that this will return false for version 1, since there is no versionWF.
    false
  end

  # @return [Boolean] true if the object has previously been accessioned.
  def accessioned?
    return true if workflow_client.lifecycle(druid:, milestone_name: 'accessioned')

    false
  end

  private

  attr_reader :druid, :version

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end

  # @return [Boolean] true if there is a workflow for the current version and it has incomplete steps.
  def active_workflow?(workflow:)
    workflow_response = workflow_client.workflow(pid: druid, workflow_name: workflow)
    # Note that active_for? checks if there are any steps in this workflow.
    # This is a different meaning of active used in this class.
    # Is there a workflow for the current version? If not, then it can't be active.
    return false unless workflow_response.active_for?(version:)

    # There are incomplete steps in the workflow.
    !workflow_response.complete_for?(version:)
  end

  def active_workflow_except_step?(workflow:, process:)
    workflow_response = workflow_client.workflow(pid: druid, workflow_name: workflow)

    # Is there a workflow for the current version? If not, then it can't be active.
    return false unless workflow_response.active_for?(version:)

    # Does the active workflow contain any processes *other* than the one we're ignoring? If so, consider it active.
    workflow_response.incomplete_processes_for(version:).any? { |step| step.name != process }
  end
end

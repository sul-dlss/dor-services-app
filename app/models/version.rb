# frozen_string_literal: true

# Represents a version of a digital object with associated context for workflow steps.
# All workflow steps occur on to a particular version.
class Version
  def initialize(druid:, version:, context: nil)
    @druid = druid
    @version_id = version
    @context = context # this is context as a hash to be stored in the VersionContext table
  end

  attr_reader :druid, :version_id, :context

  def update_context
    # if no context is passed in (nil), do nothing
    return unless context

    # if context is passed in but is empty, delete the version context record to clear all context
    if context.blank?
      VersionContext.find_by(druid:, version: version_id)&.destroy
    else # otherwise, create/update the version context record as json in the database
      VersionContext.find_or_create_by(druid:, version: version_id).update!(values: context)
    end
  end

  # @return [ActiveRecord::Relationship] an ActiveRecord scope that has the WorkflowSteps for this version
  def workflow_steps(workflow)
    WorkflowStep.where(druid:, version: version_id, workflow:)
  end
end

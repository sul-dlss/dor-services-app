# frozen_string_literal: true

# Monitors stuck workflows
class WorkflowMonitor
  # Look for "queued" steps that are more than 24 hours old
  # and "started" steps that are more than 48 hours old
  def self.monitor
    new.monitor
  end

  def monitor
    monitor_queued_steps
    monitor_started_steps
  end

  private

  def monitor_started_steps
    steps = WorkflowStep.started
                        .where(WorkflowStep.arel_table[:updated_at].lt(48.hours.ago))
                        .order(:druid, :version)
                        .limit(1000)

    return if steps.count.zero?

    Honeybadger.notify('Workflow step(s) has been running for more than 48 hours. Perhaps there is a problem.',
                       context: context_from(steps))
  end

  def monitor_queued_steps
    queued = WorkflowStep.queued
                         .where(WorkflowStep.arel_table[:updated_at].lt(24.hours.ago))
                         .order(:druid, :version)
                         .limit(1000)
    return if queued.count.zero?

    Honeybadger.notify('Workflow step(s) have been queued for more than 24 hours. Perhaps there is a ' \
                       'problem with the robots.', context: context_from(queued))
  end

  def context_from(steps)
    { steps: steps.map do |step|
      { druid: step.druid, version: step.version, workflow: step.workflow, process: step.process }
    end }
  end
end

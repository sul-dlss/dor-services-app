# frozen_string_literal: true

# Find the next steps in the workflow that are ready to be performed.
class NextStepService
  include Singleton

  # @param [WorkflowStep] step
  def self.enqueue_next_steps(step:)
    instance.enqueue_next_steps(step:)
  end

  def initialize
    @workflows = {}
  end

  # @param [WorkflowStep] step
  # @return [ActiveRecord::Relation] a list of WorkflowSteps that have been enqueued
  def enqueue_next_steps(step:)
    next_steps = find_next(step:)
    if last_accession_step?(step)
      # https://github.com/sul-dlss/argo/issues/3817
      # Theory is that many commits to solr are not being executed in the correct order, resulting in
      # older data being indexed last.  This is an attempt to force a delay when indexing the very
      # last step of the accessionWF.
      sleep 1

      # In theory, notifications should be sent for every step.
      # However, currently consumers only care about the end-accession step.
      Notifications::WorkflowStepUpdated.publish(step:)
    end

    Indexer.reindex_later(druid: step.druid)
    next_steps
  end

  private

  # @param [WorkflowStep] step
  # @return [ActiveRecord::Relation] a list of WorkflowSteps
  def find_next(step:) # rubocop:disable Metrics/AbcSize
    steps = Version.new(druid: step.druid, version: step.version).workflow_steps(step.workflow)

    completed_steps = steps.complete.pluck(:process)

    # Find workflow/version/steps and subtract what we've completed so far.
    todo = workflow(step.workflow).except(*completed_steps)

    # Now filter by the steps that we have the prerequisites done for:
    ready = todo.select { |_, process| (process.prerequisites - completed_steps).empty? && !process.skip_queue }.keys

    results = WorkflowStep.transaction do
      set = steps.waiting.lock.where(process: ready)
      results_before_update = set.to_a
      set.update_all(status: 'queued') # rubocop:disable Rails/SkipsModelValidations
      results_before_update
    end

    # We must not enqueue steps before the transaction completes, otherwise the workers
    # could start working on it and find it to still be "waiting".
    results.each { |next_step| QueueService.enqueue(next_step) }
  end

  def workflow(workflow)
    @workflows[workflow] ||= load_workflow(workflow)
  end

  # @return [Hash<Process>]
  def load_workflow(workflow)
    doc = Workflow::TemplateLoader.load_as_xml(workflow)
    raise "Workflow #{workflow} not found" if doc.nil?

    parser = Workflow::TemplateParser.new(doc)
    parser.processes.index_by(&:name)
  end

  def last_accession_step?(step)
    step.workflow == 'accessionWF' && step.process == 'end-accession' && step.status == 'completed'
  end
end

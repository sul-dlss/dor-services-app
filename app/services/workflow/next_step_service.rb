# frozen_string_literal: true

module Workflow
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
    def enqueue_next_steps(step:)
      all_steps = Version.new(druid: step.druid, version: step.version).workflow_steps(step.workflow)
      ready_process_names = ready_processes_for(all_steps:, step:)

      queued_steps = queued_steps_for(ready_process_names:, all_steps:)

      Indexer.reindex_now(druid: step.druid)

      # We must not enqueue steps before the transaction completes, otherwise the workers
      # could start working on it and find it to still be "waiting".
      queued_steps.each { |next_step| QueueService.enqueue(next_step) }

      perform_notification(step:)

      queued_steps
    end

    private

    # @param [WorkflowStep] step
    # @return [ActiveRecord::Relation] a list of WorkflowSteps
    def find_next(step:)
      all_steps = Version.new(druid: step.druid, version: step.version).workflow_steps(step.workflow)
      ready_process_names = ready_processes_for(all_steps:, step:)

      queued_steps = queued_steps_for(ready_process_names:, all_steps:)

      # We must not enqueue steps before the transaction completes, otherwise the workers
      # could start working on it and find it to still be "waiting".
      queued_steps.each { |next_step| QueueService.enqueue(next_step) }
    end

    # @return [Array<String>] the names of the processes that are ready to be queued
    def ready_processes_for(all_steps:, step:)
      completed_process_names = all_steps.complete.pluck(:process)

      # Find workflow/version/steps and subtract what we've completed so far.
      todo_processes_map = workflow(step.workflow).except(*completed_process_names)

      # Now filter by the steps that we have the prerequisites done for:
      todo_processes_map.select do |_, process|
        (process.prerequisites - completed_process_names).empty? && !process.skip_queue
      end.keys
    end

    # @return [Array<WorkflowStep>] the steps that were updated to 'queued'
    def queued_steps_for(ready_process_names:, all_steps:)
      WorkflowStep.transaction do
        ready_steps = all_steps.waiting.lock.where(process: ready_process_names)
        ready_steps_before_update = ready_steps.to_a
        ready_steps.update_all(status: 'queued') # rubocop:disable Rails/SkipsModelValidations
        ready_steps_before_update
      end
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

    def perform_notification(step:)
      return unless last_accession_step?(step)

      # https://github.com/sul-dlss/argo/issues/3817
      # Theory is that many commits to solr are not being executed in the correct order, resulting in
      # older data being indexed last.  This is an attempt to force a delay when indexing the very
      # last step of the accessionWF.
      sleep 1

      # In theory, notifications should be sent for every step.
      # However, currently consumers only care about the end-accession step.
      Notifications::WorkflowStepUpdated.publish(step:)
    end
  end
end

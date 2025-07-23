# frozen_string_literal: true

namespace :workflow do
  desc 'Update a workflow step'
  task :step, %i[druid workflow process version status] => :environment do |_task, args|
    # This initializes rabbit, which is needed since rake task isn't run in Phusion Passenger.
    RabbitFactory.start_global

    step = WorkflowStep.find_by(
      druid: args[:druid],
      workflow: args[:workflow],
      process: args[:process],
      version: args[:version]
    )

    raise 'Workflow step does not already exist' if step.nil?

    step.update(status: args[:status], error_msg: nil)
    puts("Setting #{args[:process]} to #{args[:status]}")

    # Enqueue next steps
    NextStepService.enqueue_next_steps(step:)
  end
end

# frozen_string_literal: true

# Service for add workflow steps to Sidekiq queues
class QueueService
  # Enqueue the provided step
  # NOTE: This should only be called by one process at a time. Wrap this in a database row lock.
  # @param [WorkflowStep] workflow step to enqueue
  def self.enqueue(step)
    QueueService.new(step).enqueue
  end

  attr_reader :step

  # @param [WorkflowStep] workflow step to enqueue
  def initialize(step)
    @step = step
  end

  # Enqueue the provided step
  def enqueue
    queue_name = build_queue_name
    job_id = ROBOT_SIDEKIQ_CLIENT.push('queue' => queue_name, 'class' => class_name,
                                       'args' => [step.druid, step.version])
    raise "Enqueueing #{class_name} for #{step.druid} to #{queue_name} failed." unless job_id

    Rails.logger.info "Enqueued #{class_name} for #{step.druid} to #{queue_name}: #{job_id}"
  end

  DSA_ROBOTS = [
    'Robots::DorRepo::Accession::Publish',
    'Robots::DorRepo::Accession::ReleaseInitiate',
    'Robots::DorRepo::Accession::Shelve',
    'Robots::DorRepo::Accession::ResetWorkspace',
    'Robots::DorRepo::Accession::SdrIngestTransfer',
    'Robots::DorRepo::Accession::UpdateDoi',
    'Robots::DorRepo::Accession::UpdateOrcidWork',
    'Robots::DorRepo::Goobi::GoobiNotify',
    'Robots::DorRepo::Release::Start',
    'Robots::DorRepo::Release::ReleaseMembers',
    'Robots::DorRepo::Release::ReleasePublish',
    'Robots::DorRepo::Release::UpdateHoldings'
  ].freeze

  SPECIAL_ROBOTS = {
    # Special case because this robot can eats up too much memory if more
    # than one instance is running on a worker box simultaneously
    'Robots::DorRepo::Assembly::Jp2Create' => 'assemblyWF_jp2',
    # Special case so that can single thread Folio updates
    'Robots::DorRepo::Release::UpdateMarc' => 'releaseWF_update-marc_dsa'
  }.freeze

  # Include the process name in the queue name to allow for greater sidekiq control.
  QUEUE_PER_PROCESS_WORKFLOWS = %w[accessionWF].freeze

  private

  # Generate the queue name from step
  #
  # @example
  #     => 'assemblyWF_default'
  #     => 'assemblyWF_low'
  def build_queue_name
    return SPECIAL_ROBOTS[class_name] if SPECIAL_ROBOTS.include?(class_name)

    queue_name = step.workflow
    queue_name += "_#{step.process}" if QUEUE_PER_PROCESS_WORKFLOWS.include?(step.workflow)
    queue_name += "_#{step.lane_id}"
    queue_name += '_dsa' if DSA_ROBOTS.include?(class_name)
    queue_name
  end

  # Converts a given step to the Robot class name
  # Based on https://github.com/sul-dlss/lyber-core/blob/master/lib/lyber_core/robot.rb#L33
  # @example
  #     => 'Robots::DorRepo::Assembly::Jp2Create'
  def class_name
    @class_name ||= begin
      repo = %w[preservationIngestWF sdrIngestWF].include?(step.workflow) ? 'Sdr' : 'Dor'
      workflow = step.workflow.sub('WF', '').camelize
      process = step.process.tr('-', '_').camelize
      "Robots::#{repo}Repo::#{workflow}::#{process}"
    end
  end
end

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
    job_id = ROBOT_SIDEKIQ_CLIENT.push('queue' => queue_name, 'class' => class_name, 'args' => [step.druid])
    raise "Enqueueing #{class_name} for #{step.druid} to #{queue_name} failed." unless job_id

    Rails.logger.info "Enqueued #{class_name} for #{step.druid} to #{queue_name}: #{job_id}"
  end

  DSA_ROBOTS = [
    'Robots::DorRepo::Accession::Publish',
    'Robots::DorRepo::Accession::Shelve',
    'Robots::DorRepo::Accession::ResetWorkspace',
    'Robots::DorRepo::Accession::SdrIngestTransfer',
    'Robots::DorRepo::Accession::UpdateDoi',
    'Robots::DorRepo::Accession::UpdateOrcidWork',
    'Robots::DorRepo::Goobi::GoobiNotify'
  ].freeze

  SPECIAL_ROBOTS = {
    # Special case because this robot can eats up too much memory if more
    # than one instance is running on a worker box simultaneously
    'Robots::DorRepo::Assembly::Jp2Create' => 'assemblyWF_jp2',
    # Special case so that can single thread Folio updates
    'Robots::DorRepo::Release::UpdateMarc' => 'releaseWF_update-marc_dsa'
  }.freeze

  private

  # Generate the queue name from step
  #
  # @example
  #     => 'assemblyWF_default'
  #     => 'assemblyWF_low'
  def queue_name
    @queue_name ||= if SPECIAL_ROBOTS.include?(class_name)
                      SPECIAL_ROBOTS[class_name]
                    elsif DSA_ROBOTS.include?(class_name)
                      # DSA only handles certain robots. Those need to be sent to separate queues.
                      "#{step.workflow}_#{step.lane_id}_dsa"
                    else
                      "#{step.workflow}_#{step.lane_id}"
                    end
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

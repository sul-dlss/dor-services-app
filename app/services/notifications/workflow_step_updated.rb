# frozen_string_literal: true

module Notifications
  # Send a message to a RabbitMQ exchange that a workflow step has been updated.
  class WorkflowStepUpdated
    def self.publish(step:)
      return unless Settings.rabbitmq.enabled

      Rails.logger.info "Publishing Rabbitmq Message for #{step.druid}: #{step.process}.#{step.status}"
      new(step:, channel: RabbitChannel.instance).publish
      Rails.logger.info "Published Rabbitmq Message for #{step.druid}: #{step.process}.#{step.status}"
    end

    def initialize(step:, channel:)
      @step = step
      @channel = channel
    end

    def publish
      message = step.attributes_for_process.merge(action: 'workflow updated', druid: step.druid)
      exchange.publish(message.to_json, routing_key: "#{step.process}.#{step.status}")
    end

    private

    def exchange
      channel.topic('sdr.workflow')
    end

    attr_reader :step, :channel
  end
end

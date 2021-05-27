# frozen_string_literal: true

module Notifications
  # Send a message to a RabbitMQ exchange that an embargo has been removed from an item.
  # The primary use case here is that h2 needs to log a message when this happens
  class EmbargoLifted
    def self.publish(model:)
      Rails.logger.debug "Publishing Rabbitmq Message for embargo #{model.externalIdentifier}"
      new(model: model, channel: RabbitChannel.instance).publish
      Rails.logger.debug "Published Rabbitmq Message for embargo #{model.externalIdentifier}"
    end

    def initialize(model:, channel:)
      @model = model
      @channel = channel
    end

    def publish
      message = { model: model.to_h }
      exchange.publish(message.to_json, routing_key: routing_key)
    end

    private

    attr_reader :model, :channel

    def exchange
      channel.topic('sdr.objects.embargo_lifted')
    end

    # Using the project as a routing key because listeners may only care about their projects.
    def routing_key
      model.is_a?(Cocina::Models::AdminPolicy) ? 'SDR' : model.administrative.partOfProject
    end
  end
end

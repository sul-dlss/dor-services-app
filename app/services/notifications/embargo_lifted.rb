# frozen_string_literal: true

module Notifications
  # Send a message to a RabbitMQ exchange that an embargo has been removed from an item.
  # The primary use case here is that h2 needs to log a message when this happens
  class EmbargoLifted
    def self.publish(model:)
      return unless Settings.rabbitmq.enabled

      Rails.logger.debug "Publishing Rabbitmq Message for embargo #{model.externalIdentifier}"
      new(model:, channel: RabbitChannel.instance).publish
      Rails.logger.debug "Published Rabbitmq Message for embargo #{model.externalIdentifier}"
    end

    def initialize(model:, channel:)
      @model = Cocina::Models.without_metadata(model)
      @channel = channel
    end

    def publish
      message = { model: model.to_h }
      exchange.publish(message.to_json, routing_key:)
    end

    private

    attr_reader :model, :channel

    def exchange
      channel.topic('sdr.objects.embargo_lifted')
    end

    # Using the project as a routing key because listeners may only care about their projects.
    def routing_key
      if model.is_a?(Cocina::Models::AdminPolicy)
        'SDR'
      else
        AdministrativeTags.project(identifier: model.externalIdentifier).first
      end
    end
  end
end

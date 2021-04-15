# frozen_string_literal: true

module Notifications
  # Send a message to a RabbitMQ exchange that an item has been updated.
  # The primary use case here is that an index may need to be updated (dor-indexing-app)
  class ObjectUpdated
    def self.publish(model:)
      Rails.logger.debug "Publishing Rabbitmq Message for updating #{model.externalIdentifier}"
      new(model: model, channel: RabbitChannel.instance).publish
      Rails.logger.debug "Published Rabbitmq Message for updating #{model.externalIdentifier}"
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
      channel.topic('sdr.objects.updated')
    end

    # Using the project as a routing key because listeners may only care about their projects.
    def routing_key
      model.is_a?(Cocina::Models::AdminPolicy) ? 'SDR' : model.administrative.partOfProject
    end
  end
end

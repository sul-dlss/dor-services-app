# frozen_string_literal: true

module Notifications
  # Send a message to a RabbitMQ exchange that an item has been deleted.
  # The primary use case here is that an index may need to be updated (dor-indexing-app)
  class ObjectDeleted
    def self.publish(model:, deleted_at:)
      return unless Settings.rabbitmq.enabled

      Rails.logger.debug "Publishing Rabbitmq Message for deleting #{model.externalIdentifier}"
      new(model:, deleted_at:, channel: RabbitChannel.instance).publish
      Rails.logger.debug "Published Rabbitmq Message for deleting #{model.externalIdentifier}"
    end

    def initialize(model:, deleted_at:, channel:)
      @model = model
      @deleted_at = deleted_at
      @channel = channel
    end

    def publish
      message = {
        druid: model.externalIdentifier,
        deleted_at: deleted_at.to_datetime.httpdate
      }
      exchange.publish(message.to_json, routing_key:)
    end

    private

    attr_reader :model, :deleted_at, :channel

    def exchange
      channel.topic('sdr.objects.deleted')
    end

    # Using the project as a routing key because listeners may only care about their projects.
    def routing_key
      model.is_a?(Cocina::Models::AdminPolicy) ? 'SDR' : AdministrativeTags.project(identifier: model.externalIdentifier).first
    end
  end
end

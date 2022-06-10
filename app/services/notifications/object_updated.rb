# frozen_string_literal: true

module Notifications
  # Send a message to a RabbitMQ exchange that an item has been updated.
  # The primary use case here is that an index may need to be updated (dor-indexing-app)
  class ObjectUpdated
    def self.publish(model:)
      return unless Settings.rabbitmq.enabled

      Rails.logger.debug "Publishing Rabbitmq Message for updating #{model.externalIdentifier}"
      new(model:, channel: RabbitChannel.instance).publish
      Rails.logger.debug "Published Rabbitmq Message for updating #{model.externalIdentifier}"
    end

    def initialize(model:, channel:)
      @model = model
      @channel = channel
    end

    def publish
      message = {
        model: Cocina::Models.without_metadata(model).to_h,
        created_at: model.created.to_datetime.httpdate,
        modified_at: model.modified.to_datetime.httpdate
      }
      exchange.publish(message.to_json, routing_key:)
    end

    private

    attr_reader :model, :channel

    def exchange
      channel.topic('sdr.objects.updated')
    end

    # Using the project as a routing key because listeners may only care about their projects.
    def routing_key
      model.is_a?(Cocina::Models::AdminPolicyWithMetadata) ? 'SDR' : AdministrativeTags.project(identifier: model.externalIdentifier).first
    end
  end
end

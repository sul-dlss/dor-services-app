# frozen_string_literal: true

module Notifications
  # Send a message to a RabbitMQ exchange that an item has been created.
  # The primary use case here is that the requestor may want to know what druid was assigned to the request.
  class ObjectCreated
    def self.publish(model:, created_at:, modified_at:)
      return unless Settings.rabbitmq.enabled

      # Skipping APOs because they don't (yet) have a partOfProject assertion.
      return if model.is_a? Cocina::Models::AdminPolicy

      Rails.logger.debug "Publishing Rabbitmq Message for creating #{model.externalIdentifier}"
      new(model:, created_at:, modified_at:, channel: RabbitChannel.instance).publish
      Rails.logger.debug "Published Rabbitmq Message for creating #{model.externalIdentifier}"
    end

    def initialize(model:, created_at:, modified_at:, channel:)
      @model = model
      @created_at = created_at
      @modified_at = modified_at
      @channel = channel
    end

    def publish
      message = {
        model: model.to_h,
        created_at: created_at.to_datetime.httpdate,
        modified_at: modified_at.to_datetime.httpdate
      }
      # Using the project as a routing key because listeners may only care about their projects.
      exchange.publish(message.to_json, routing_key: AdministrativeTags.project(identifier: model.externalIdentifier).first)
    end

    private

    def exchange
      channel.topic('sdr.objects.created')
    end

    attr_reader :model, :channel, :created_at, :modified_at
  end
end

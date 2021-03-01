# frozen_string_literal: true

module Notifications
  # Send a message to a RabbitMQ exchange that an item has been created.
  # The primary use case here is that the requestor may want to know what druid was assigned to the request.
  class ObjectCreated
    def self.publish(model:)
      # Skipping APOs because they don't (yet) have a partOfProject assertion.
      return if model.is_a? Cocina::Models::AdminPolicy

      Rails.logger.info "Publishing Rabbitmq Message for #{model.externalIdentifier}"
      new(model: model, channel: channel).publish
      Rails.logger.info "Published Rabbitmq Message for #{model.externalIdentifier}"
    end

    def self.channel
      @channel ||= connection.create_channel
    end

    def self.connection
      @connection ||= Bunny.new(hostname: Settings.rabbitmq.hostname,
                                vhost: Settings.rabbitmq.vhost,
                                username: Settings.rabbitmq.username,
                                password: Settings.rabbitmq.password).tap(&:start)
    end

    def initialize(model:, channel:)
      @model = model
      @channel = channel
    end

    def publish
      message = { model: model.to_h }
      exchange = channel.topic('sdr.objects.created')
      # Using the project as a routing key because listeners may only care about their projects.
      exchange.publish(message.to_json, routing_key: model.administrative.partOfProject)
    end

    private

    attr_reader :model, :channel
  end
end

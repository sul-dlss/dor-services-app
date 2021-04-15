# frozen_string_literal: true

module Notifications
  # Creates a connection to RabbitMQ using the Bunny gem
  class RabbitChannel
    include Singleton

    delegate :topic, to: :channel

    def channel
      @channel ||= connection.create_channel
    end

    def connection
      @connection ||= Bunny.new(hostname: Settings.rabbitmq.hostname,
                                vhost: Settings.rabbitmq.vhost,
                                username: Settings.rabbitmq.username,
                                password: Settings.rabbitmq.password).tap(&:start)
    end
  end
end

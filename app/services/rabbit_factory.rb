# frozen_string_literal: true

# Factory for initializing global RabbitMQ connection and channel.
class RabbitFactory
  # rubocop:disable Style/GlobalVars
  def self.start_global
    $rabbitmq_connection = Bunny.new(hostname: Settings.rabbitmq.hostname,
                                     vhost: Settings.rabbitmq.vhost,
                                     username: Settings.rabbitmq.username,
                                     password: Settings.rabbitmq.password)
    $rabbitmq_connection.start

    $rabbitmq_channel = $rabbitmq_connection.create_channel
  end
  # rubocop:enable Style/GlobalVars
end

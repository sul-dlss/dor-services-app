# frozen_string_literal: true

# Since we're using Passenger, we need to (re)establish our RabbitMQ connection
# after Passenger forks a new process. Otherwise we can end up with errors like:
#   Bunny::ConnectionClosedError: Trying to send frame through a closed connection.
#
# See http://rubybunny.info/articles/connecting.html#using_bunny_with_passenger
# rubocop:disable Style/GlobalVars
if defined?(PhusionPassenger) # otherwise it breaks rake commands if you put this in an initializer
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      # We're in a smart spawning mode
      # Now is a good time to connect to RabbitMQ
      RabbitFactory.start_global
    end
  end

  PhusionPassenger.on_event(:stopping_worker_process) do
    $rabbitmq_connection&.close
  end
end
# rubocop:enable Style/GlobalVars

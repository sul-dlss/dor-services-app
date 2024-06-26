# frozen_string_literal: true

namespace :rabbitmq do
  desc 'Setup routing'
  task setup: :environment do
    require 'bunny'

    conn = Bunny.new(hostname: Settings.rabbitmq.hostname,
                     vhost: Settings.rabbitmq.vhost,
                     username: Settings.rabbitmq.username,
                     password: Settings.rabbitmq.password).tap(&:start)

    channel = conn.create_channel

    # connect topic to the queue

    exchange = channel.topic('sdr.objects.event')
    queue = channel.queue('dsa.create-event', durable: true)
    queue.bind(exchange, routing_key: '#')

    # These messages look like this: { druid: step.druid, action: 'workflow updated' }
    # and they have a routing key like this: 'end-accession.completed')
    # So if the volume here is too high, we can filter the routing keys to *.errored and end-accession.*
    exchange = channel.topic('sdr.workflow')
    queue = channel.queue('dor.indexing-by-druid', durable: true)
    queue.bind(exchange, routing_key: '#')

    conn.close
  end
end

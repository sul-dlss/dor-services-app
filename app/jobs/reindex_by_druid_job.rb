# frozen_string_literal: true

# Reindexes an object given a druid.
# This worker will connect to "dor.indexing-by-druid" queue. This queue is populated when
# the workflow service makes new RabbitMQ messages on the sdr.workflow exchange.
# @see https://github.com/sul-dlss/dor-services-app/blob/144676b9dbe4f2c0ea3687b3267343e504fac35b/lib/tasks/rabbitmq.rake#L24-L25
class ReindexByDruidJob
  include Sneakers::Worker

  # env is set to nil since by default the queue name would be "dor.indexing-by-druid_development"
  from_queue 'dor.indexing-by-druid', env: nil

  def work(msg)
    druid = JSON.parse(msg).fetch('druid')
    Indexer.reindex_later(druid: druid)
    ack!
  end
end

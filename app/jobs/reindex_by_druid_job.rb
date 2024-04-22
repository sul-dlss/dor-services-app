# frozen_string_literal: true

# Reindexes an object given a druid.
# This worker will connect to "dor.indexing-by-druid" queue. This queue is populated when
# the workflow service makes new RabbitMQ messages on the sdr.workflow exchange.
# @see https://github.com/sul-dlss/dor_indexing_app/blob/8546e8aabb76d506fe3f5f5ea43ae499a442d75f/lib/tasks/rabbitmq.rake#L20-L21
class ReindexByDruidJob
  include Sneakers::Worker

  # env is set to nil since by default the queue name would be "dor.indexing-by-druid_development"
  from_queue 'dor.indexing-by-druid', env: nil

  def work(msg)
    druid = druid_from_message(msg)
    cocina_object = CocinaObjectStore.find(druid)
    Indexer.reindex(cocina_object:)
    ack!
  rescue CocinaObjectStore::CocinaObjectNotFoundError
    Honeybadger.notify('Cannot reindex since not found. This may be because applications (e.g., PresCat) are creating workflow steps for deleted objects.',
                       { druid: druid_from_message(msg) })
    Rails.logger.info("Cannot reindex #{druid_from_message(msg)} by druid since it is not found.")
    ack!
  end

  def druid_from_message(str)
    JSON.parse(str).fetch('druid')
  end
end

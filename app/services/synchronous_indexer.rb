# frozen_string_literal: true

# Most of the indexing happens when dor_indexing_app receives a RabbitMQ message from dor-services-app
# When we can't have latency in the indexing, we can use this class to directly call dor-indexing-app
class SynchronousIndexer
  def self.reindex_remotely_from_cocina(cocina_object:, created_at:, updated_at:)
    body = { cocina_object: Cocina::Models.without_metadata(cocina_object), created_at:, updated_at: }.to_json
    result = connection.put('reindex_from_cocina', body, { 'Content-Type' => 'application/json' })
    return if result.success?

    error_message = "Response for reindexing was an error. #{result.status}: #{result.body}"
    Honeybadger.notify(error_message, { druid: cocina_object.externalIdentifier })
    Rails.logger.error(error_message)
  end

  def self.connection
    Faraday.new(url: Settings.dor_indexing.url) do |conn|
      conn.headers[:user_agent] = 'dor-services-app'
      conn.request(:retry, max: 3,
                           methods: %i[post put],
                           exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed])
      conn.adapter(:net_http) # NB: Last middleware must be the adapter
    end
  end
  private_class_method :connection
end

# frozen_string_literal: true

# Most of the indexing happens when Fedora sends an activeMQ message to dor_indexing_app
# When we can't have latency in the indexing, we can use this class to directly call dor-indexing-app
class SynchronousIndexer
  def self.reindex_remotely(identifier)
    result = connection.post("reindex/#{identifier}")
    return if result.success?

    error_message = "Response for reindexing was an error. #{result.status}: #{result.body}"
    Honeybadger.notify(error_message, { druid: identifier })
    Rails.logger.error(error_message)
  end

  def self.connection
    Faraday.new(url: Settings.dor_indexing.url) do |conn|
      conn.headers[:user_agent] = 'dor-services-app'
      conn.request(:retry, max: 3,
                           methods: [:post],
                           exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed])
      conn.adapter(:net_http) # NB: Last middleware must be the adapter
    end
  end
  private_class_method :connection
end

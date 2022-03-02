# frozen_string_literal: true

# Functions for querying solr
class SolrService
  include Singleton

  def options
    { timeout: Settings.solr.timeout, url: Settings.solr.url }
  end

  def conn
    @conn ||= RSolr.connect options
  end

  class << self
    delegate :conn, to: :instance

    def select_path
      Settings.solr.select_path
    end

    # @param [Hash] options
    def get(query, args = {})
      args = args.merge(q: query, wt: :json)
      conn.get(select_path, params: args)
    end

    def query(query, args = {})
      unless args.key?(:rows)
        Rails.logger.warn "Calling SolrService.get without passing an explicit value for ':rows' is not recommended. " \
                          "You will end up with Solr's default (usually set to 10)\nCalled by #{caller(1..1).first}"
      end
      get(query, args).fetch('response').fetch('docs')
    end

    delegate :add, :commit, to: :conn
  end
end

# frozen_string_literal: true

# Indexes a Cocina object.
class Indexer
  # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata]
  def self.reindex(cocina_object:, trace_id: nil)
    return unless Settings.solr.enabled

    trace_id ||= trace_id_for(druid: cocina_object.externalIdentifier)
    solr_doc = Indexing::Builders::DocumentBuilder.for(
      model: cocina_object,
      trace_id:
    ).to_solr
    solr.add(solr_doc)
    # This logging is to assist with https://github.com/sul-dlss/dor-services-app/issues/5231
    # It is capturing that a Solr document is being committed and the order relative to other commits.
    if Settings.indexer.logging
      Rails.logger.info("[Indexing] Committing #{cocina_object.externalIdentifier} with trace_id=#{trace_id}")
    end
    solr.commit
  end

  def self.validate_descriptive(cocina_object:)
    return unless Settings.solr.enabled

    Indexing::Indexers::DescriptiveMetadataIndexer.new(cocina: cocina_object).to_solr
  end

  def self.delete(druid:)
    return unless Settings.solr.enabled

    solr.delete_by_id(druid)
    solr.commit
  end

  # Reindex now, with fallback to later if a deadlock occurs.
  def self.reindex_now(druid:, trace_id: nil, fallback_to_later: true)
    trace_id ||= trace_id_for(druid: druid)
    ReindexJob.perform_now(
      druid:,
      trace_id:
    )
  rescue ReindexJob::DeadLockError
    raise unless fallback_to_later

    Rails.logger.warn("Deadlock reindexing #{druid}, falling back to reindex_later (trace_id: #{trace_id})")
    reindex_later(druid: druid, trace_id:)
  end

  # @param [string] druid
  def self.reindex_later(druid:, trace_id: nil)
    # Note that there is an issue whereby active jobs are getting enqueued to the robot redis instance.
    # See https://github.com/sidekiq/sidekiq/issues/6817
    Sidekiq::Client.via(REDIS) do
      ReindexJob.perform_later(
        druid:,
        trace_id: trace_id || trace_id_for(druid:)
      )
    end
  end

  def self.solr
    RSolr.connect(timeout: 120, open_timeout: 120, url: Settings.solr.url)
  end
  private_class_method :solr

  def self.trace_id_for(druid:)
    source = Kernel.caller_locations(2, 1).first.to_s.delete_prefix("#{Rails.root}/") # rubocop:disable Rails/FilePath
    SecureRandom.uuid.tap do |trace_id|
      if Settings.indexer.logging
        Rails.logger.info("[Indexing] Reindexing #{druid} from #{source} with trace_id=#{trace_id}")
      end
    end
  end
end

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
    Rails.logger.info("[Indexing] Committing #{cocina_object.externalIdentifier} with trace_id=#{trace_id}")
    solr.commit
  end

  def self.delete(druid:)
    return unless Settings.solr.enabled

    solr.delete_by_id(druid)
    solr.commit
  end

  # @param [string] druid
  def self.reindex_later(druid:, trace_id: nil)
    ReindexJob.perform_later(
      druid:,
      trace_id: trace_id || trace_id_for(druid:)
    )
  end

  def self.solr
    RSolr.connect(timeout: 120, open_timeout: 120, url: Settings.solr.url)
  end
  private_class_method :solr

  def self.trace_id_for(druid:)
    source = Kernel.caller_locations(2, 1).first.to_s.delete_prefix("#{Rails.root}/") # rubocop:disable Rails/FilePath
    SecureRandom.uuid.tap do |trace_id|
      Rails.logger.info("[Indexing] Reindexing #{druid} from #{source} with trace_id=#{trace_id}")
    end
  end
end

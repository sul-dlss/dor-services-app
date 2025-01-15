# frozen_string_literal: true

# Indexes a Cocina object.
class Indexer
  # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata]
  def self.reindex(cocina_object:, trace_id: nil)
    return unless Settings.solr.enabled

    solr_doc = Indexing::Builders::DocumentBuilder.for(
      model: cocina_object,
      trace_id: trace_id || trace_id_for(druid: cocina_object.externalIdentifier)
    ).to_solr
    solr.add(solr_doc)
    solr.commit
  end

  def self.delete(druid:)
    return unless Settings.solr.enabled

    solr.delete_by_id(druid)
    solr.commit
  end

  # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata]
  def self.reindex_later(cocina_object:, trace_id: nil)
    ReindexJob.perform_later(
      model: cocina_object.to_h,
      created: cocina_object.created,
      modified: cocina_object.modified,
      trace_id: trace_id || trace_id_for(druid: cocina_object.externalIdentifier)
    )
  end

  def self.solr
    RSolr.connect(timeout: 120, open_timeout: 120, url: Settings.solr.url)
  end
  private_class_method :solr

  def self.trace_id_for(druid:)
    source = Kernel.caller_locations(2, 1).first.to_s.delete_prefix("#{Rails.root}/") # rubocop:disable Rails/FilePath
    SecureRandom.uuid.tap do |trace_id|
      Rails.logger.info("Reindexing #{druid} from #{source} with trace_id=#{trace_id}")
    end
  end
end

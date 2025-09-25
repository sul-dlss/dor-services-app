# frozen_string_literal: true

# Reindexes a batch of objects.
class BatchReindexJob < ApplicationJob
  queue_as 'batch_reindex'

  def perform(druids)
    start_time = Time.zone.now
    solr_docs = []
    RepositoryObject.includes(:head_version).where(external_identifier: druids).find_each do |repository_object|
      solr_docs << Indexing::Builders::DocumentBuilder.for(
        model: repository_object.head_version.to_cocina_with_metadata,
        trace_id: Indexer.trace_id_for(druid: repository_object.external_identifier)
      ).to_solr
    end
    solr_conn.add(solr_docs, add_attributes: { commitWithin: 500 })
    log_duration(start_time:, druids:)
  end

  def solr_conn
    RSolr.connect(timeout: 120, open_timeout: 120, url: Settings.solr.url)
  end

  def log_duration(start_time:, druids:)
    batch_duration = Time.zone.now - start_time
    Rails.logger.info("Batch reindexed #{druids.size} objects in #{batch_duration.round(0)} secs " \
                      "(#{(batch_duration / druids.size).round(2)} secs / object)")
  end
end

# frozen_string_literal: true

# Reindexes a batch of objects.
class BatchReindexJob < ApplicationJob
  queue_as 'batch_reindex'

  def perform(druids)
    @druids = druids
    start_time = Time.zone.now
    solr_docs = []
    RepositoryObject.includes(:head_version).where(external_identifier: druids).find_each do |repository_object|
      Honeybadger.context(druid: repository_object.external_identifier)
      solr_docs << build_solr_doc(repository_object:)
    end
    solr_conn.add(solr_docs, add_attributes: { commitWithin: 500 })
    log_duration(start_time:, druids:)
  end

  private

  attr_reader :druids

  def solr_conn
    RSolr.connect(timeout: 120, open_timeout: 120, url: Settings.solr.url)
  end

  def log_duration(start_time:, druids:)
    batch_duration = Time.zone.now - start_time
    Rails.logger.info("Batch reindexed #{druids.size} objects in #{batch_duration.round(0)} secs " \
                      "(#{(batch_duration / druids.size).round(2)} secs / object)")
  end

  def workflows_map
    @workflows_map ||= Workflow::BatchService.workflows(druids:)
  end

  def release_tags_map
    @release_tags_map ||= {}.tap do |map|
      ReleaseTag.where(druid: druids).find_each do |tag|
        map[tag.druid] ||= []
        map[tag.druid] << tag.to_cocina
      end
    end
  end

  def build_solr_doc(repository_object:)
    Indexing::Builders::DocumentBuilder.for(
      model: repository_object.head_version.to_cocina_with_metadata,
      workflows: workflows_map[repository_object.external_identifier],
      release_tags: release_tags_map[repository_object.external_identifier] || [],
      trace_id: Indexer.trace_id_for(druid: repository_object.external_identifier)
    ).to_solr
  end
end

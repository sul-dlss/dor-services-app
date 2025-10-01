# frozen_string_literal: true

# Reindexes a batch of objects.
class BatchReindexJob < ApplicationJob
  queue_as 'batch_reindex'

  def perform(druids)
    @druids = druids
    start_time = Time.zone.now
    solr_docs = repository_objects.map do |repository_object|
      Honeybadger.context(druid: repository_object.external_identifier)
      build_solr_doc(repository_object:)
    end
    solr_conn.add(solr_docs, add_attributes: { commitWithin: 500 })
    log_duration(start_time:, druids:)
  end

  private

  attr_reader :druids

  def repository_objects
    @repository_objects ||= RepositoryObject.includes(:head_version).where(external_identifier: druids).to_a
  end

  # @return [Array<String>] all collection druids referenced by the objects in the batch
  def collection_druids
    @collection_druids ||= repository_objects.flat_map do |repository_object|
      collection_druids_from(repository_object:)
    end.uniq
  end

  # @return [Hash<String, Cocina::Models::Collection>] map of collection druid to collection cocina object
  def collection_cocina_object_map
    @collection_cocina_object_map ||= {}.tap do |map|
      RepositoryObject.includes(:head_version)
                      .where(external_identifier: collection_druids)
                      .find_each do |collection_repository_object|
        map[collection_repository_object.external_identifier] =
          collection_repository_object.head_version.to_cocina_with_metadata
      end
    end
  end

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
      ReleaseTag.where(druid: druids + collection_druids).find_each do |tag|
        map[tag.druid] ||= []
        map[tag.druid] << tag.to_cocina
      end
    end
  end

  def milestones_map
    @milestones_map ||= Workflow::LifecycleBatchService.milestones_map(druids: druids)
  end

  def build_solr_doc(repository_object:)
    Indexing::Builders::DocumentBuilder.for(
      model: repository_object.head_version.to_cocina_with_metadata,
      workflows: workflows_map[repository_object.external_identifier],
      release_tags: release_tags_map.fetch(repository_object.external_identifier, []),
      milestones: milestones_map.fetch(repository_object.external_identifier, []),
      parent_collections: parent_collections_for(repository_object:),
      parent_collections_release_tags: parent_collections_release_tags_for(repository_object:),
      trace_id: Indexer.trace_id_for(druid: repository_object.external_identifier)
    ).to_solr
  end

  def collection_druids_from(repository_object:)
    repository_object.head_version.structural.fetch('isMemberOf', [])
  end

  def parent_collections_for(repository_object:)
    collection_druids_from(repository_object:).map do |collection_druid|
      collection_cocina_object_map[collection_druid]
    end
  end

  def parent_collections_release_tags_for(repository_object:)
    collection_druids_from(repository_object:).flat_map do |collection_druid|
      release_tags_map.fetch(collection_druid, [])
    end
  end
end

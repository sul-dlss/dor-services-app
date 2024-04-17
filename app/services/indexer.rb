# frozen_string_literal: true

# Indexes a Cocina object.
class Indexer
  # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata]
  # raises [DorIndexing::RepositoryError]
  def self.reindex(cocina_object:)
    solr_doc = DorIndexing.build(
      cocina_with_metadata: cocina_object,
      workflow_client: WorkflowClientFactory.build,
      cocina_finder:,
      administrative_tags_finder:,
      release_tags_finder:
    )
    solr.add(solr_doc)
    solr.commit
  end

  def self.delete(druid:)
    solr.delete_by_id(druid)
    solr.commit
  end

  # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata]
  def self.reindex_later(cocina_object:)
    ReindexJob.perform_later(
      model: cocina_object.to_h,
      created: cocina_object.created,
      modified: cocina_object.modified
    )
  end

  # Repository implementations backed by ActiveRecord
  def self.administrative_tags_finder
    lambda do |druid|
      AdministrativeTags.for(identifier: druid)
    end
  end

  def self.cocina_finder
    lambda do |druid|
      CocinaObjectStore.find(druid)
    rescue CocinaObjectStore::CocinaObjectStoreError => e
      raise DorIndexing::RepositoryError, e.message
    end
  end

  def self.release_tags_finder
    lambda do |druid|
      ReleaseTagService.item_tags(cocina_object: CocinaObjectStore.find(druid))
    end
  end

  def self.solr
    RSolr.connect(timeout: 120, open_timeout: 120, url: Settings.solr.url)
  end
  private_class_method :solr
end

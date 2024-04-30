# frozen_string_literal: true

# Indexes a Cocina object.
class Indexer
  # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata]
  def self.reindex(cocina_object:)
    solr_doc = Indexing::Builders::DocumentBuilder.for(
      model: cocina_object
    ).to_solr
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

  def self.solr
    RSolr.connect(timeout: 120, open_timeout: 120, url: Settings.solr.url)
  end
  private_class_method :solr
end

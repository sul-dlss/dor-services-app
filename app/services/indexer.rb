# frozen_string_literal: true

# Indexes a Cocina object.
class Indexer
  # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata]
  # raises [DorIndexing::RepositoryError]
  def self.reindex(cocina_object:)
    DorIndexing.build(
      cocina_with_metadata: cocina_object,
      workflow_client: WorkflowClientFactory.build,
      cocina_finder:,
      administrative_tags_finder:,
      release_tags_finder:
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
end

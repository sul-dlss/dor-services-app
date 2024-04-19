# frozen_string_literal: true

# Send notifications that every item in the given collection has been updated.
# This triggers a reindex and it's typically used when a collection title has been changed,
# so that all the objects can have the correct collection name indexed
class PublishItemsModifiedJob < ApplicationJob
  # @param [String] collection_identifier the identifier of the collection whos items need to be reindexed
  def perform(collection_identifier)
    MemberService.for(collection_identifier).each do |druid|
      cocina_object_with_metadata = CocinaObjectStore.find(druid)
      Indexer.reindex_later(cocina_object: cocina_object_with_metadata)
    end
  end
end

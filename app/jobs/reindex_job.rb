# frozen_string_literal: true

# Reindexes an object.
class ReindexJob < ApplicationJob
  queue_as :default

  # @param [Hash] model the cocina object attributes (without metadata)
  # @param [DateTime] created the time the object was created
  # @param [DateTime] modified the time the object was last modified
  def perform(model:, created:, modified:)
    cocina_object = Cocina::Models.build(model)
    cocina_object_with_metadata = Cocina::Models.with_metadata(cocina_object, 'void', created:, modified:)
    Indexer.reindex(cocina_object: cocina_object_with_metadata)
  rescue CocinaObjectStore::CocinaObjectStoreError => e
    Rails.logger.error("Error reindexing #{model[:externalIdentifier]}: #{e.message}")
    Honeybadger.notify(e, context: { druid: model[:externalIdentifier] })
  end
end

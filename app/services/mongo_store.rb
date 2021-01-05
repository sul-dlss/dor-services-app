# frozen_string_literal: true

require 'singleton'

# Service for interacting with Mongo.
class MongoStore
  include Singleton

  class << self
    def configure(collection:)
      instance.mongo_collection = collection
      self
    end

    delegate :insert, :upsert, :find, :reconnect, :create_indices, to: :instance
  end

  attr_writer :mongo_collection

  def insert(obj:)
    collection.insert_one(obj.to_h)
  end

  def upsert(obj:)
    collection.find_one_and_replace({ externalIdentifier: obj.externalIdentifier }, obj.to_h, { upsert: true })
  end

  def find(druid:)
    each_to_cocina(collection.find({ externalIdentifier: druid }, { limit: 1 })).first
  end

  # Reconnect the client (e.g., after Passenger forking). See application.rb.
  def reconnect
    collection.database.client.close
    collection.database.client.reconnect
  end

  # Create indices for the collection
  def create_indices
    collection.indexes.create_many([
                                     { key: { externalIdentifier: 1 }, unique: true }
                                   ])
  end

  private

  def each_to_cocina(cursor)
    cursor.map do |doc|
      Cocina::Models.build(doc.except(:_id), validate: false)
    end
  end

  def collection
    @collection ||= begin
      raise 'Mongo not enabled' unless Settings.enabled_features.mongo

      @mongo_collection
    end
  end

  # TO CONSIDER:
  # * Versioning (like Sinopia)
  # * Recording timestamp of changes.
  # * Recording Cocina model version (should this be part of cocina model?)
  # * Only upsert if changed.
end

# frozen_string_literal: true

# This is an implementation for storing objects.
class Persister
  def self.store(obj)
    obj.save!

    MongoStore.upsert(obj: obj) if Settings.enabled_features.mongo_persist_on_save
  end
end

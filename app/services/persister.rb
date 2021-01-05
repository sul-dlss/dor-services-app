# frozen_string_literal: true

# This is an implementation for storing objects.
class Persister
  def self.store(obj)
    obj.save!

    return unless Settings.enabled_features.mongo_persist_on_save

    cocina_obj = Cocina::Mapper.build(obj)
    MongoStore.upsert(obj: cocina_obj)
  end
end

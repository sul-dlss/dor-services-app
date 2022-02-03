# frozen_string_literal: true

# Partial implementation of a CocinaObjectStore backed by the cache.
class CacheCocinaObjectStore
  def initialize(loader)
    @loader = loader
  end

  def find(druid)
    fedora_object = @loader.load(druid)
    Cocina::Mapper.build(fedora_object, notifier: DataErrorNotifier.new)
  end
end

# frozen_string_literal: true

# Migrates Fedora objects to Cocina objects persisted in the DB.
class CocinaMigrationService
  def self.migrate(fedora_object)
    new(fedora_object).migrate
  end

  def initialize(fedora_object)
    @fedora_object = fedora_object
  end

  def migrate
    return if CocinaObjectStore.new.ar_exists?(fedora_object.pid)

    @cocina_object = Cocina::Mapper.build(fedora_object)
    save
  end

  private

  attr_reader :fedora_object, :cocina_object

  def save
    model_clazz = case cocina_object
                  when Cocina::Models::AdminPolicy
                    AdminPolicy
                  when Cocina::Models::DRO
                    Dro
                  when Cocina::Models::Collection
                    Collection
                  else
                    raise CocinaObjectStoreError, "unsupported type #{cocina_object&.type}"
                  end
    model_hash = model_clazz.to_model_hash(cocina_object).merge(created_at: created_at, updated_at: updated_at)
    model_clazz.create(model_hash)
  end

  def created_at
    fedora_object.create_date.to_datetime
  end

  def updated_at
    fedora_object.modified_date.to_datetime
  end
end

# frozen_string_literal: true

module Cocina
  # This is an implementation for storing Cocina objects.
  class ObjectStore
    # Saves a Cocina object.
    # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_obj
    def self.save(cocina_obj)
      model_clazz = case cocina_obj
                    when Cocina::Models::AdminPolicy
                      AdminPolicy
                    when Cocina::Models::DRO
                      Dro
                    when Cocina::Models::Collection
                      Collection
                    else
                      raise "unsupported type #{cocina_obj.type}"
                    end
      model_clazz.upsert_cocina(cocina_obj)
    end

    # Find a persisted Cocina object.
    # @param [String] druid to find
    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    def self.find(druid)
      Dro.find_by(druid: druid)&.to_cocina ||
        AdminPolicy.find_by(druid: druid)&.to_cocina ||
        Collection.find_by(druid: druid)&.to_cocina
    end

    # Find a persisted DRO object.
    # @param [String] druid to find
    # @return [Cocina::Models::DRO]
    def self.find_dro(druid)
      Dro.find_by(druid: druid)&.to_cocina
    end

    # Find a persisted AdminPolicy object.
    # @param [String] druid to find
    # @return [Cocina::Models::AdminPolicy]
    def self.find_admin_policy(druid)
      AdminPolicy.find_by(druid: druid)&.to_cocina
    end

    # Find a persisted Collection object.
    # @param [String] druid to find
    # @return [Cocina::Models::Collection]
    def self.find_collection(druid)
      Collection.find_by(druid: druid)&.to_cocina
    end

    # Save a Fedora object as a Cocina object.
    # @param [Dor::Abstract] item the Fedora object to save
    def self.save_fedora(fedora_obj)
      save(Cocina::Mapper.build(fedora_obj))
    end
  end
end

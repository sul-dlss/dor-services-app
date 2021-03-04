# frozen_string_literal: true

module Cocina
  # This is an implementation for storing models using ActiveFedora
  class ActiveFedoraPersister
    def self.store(obj)
      obj.save!

      return unless Settings.enabled_features.cocina_persist_on_save

      ObjectStore.save_fedora(obj)
    end
  end
end

# frozen_string_literal: true

module Cocina
  # This is an implementation for storing models using ActiveFedora
  class ActiveFedoraPersister
    def self.store(obj)
      obj.save!
    end
  end
end

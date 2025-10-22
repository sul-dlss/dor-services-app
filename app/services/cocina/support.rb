# frozen_string_literal: true

module Cocina
  # Support methods for Cocina models
  class Support
    def self.dark?(cocina_object)
      cocina_object.access.view == 'dark'
    end
  end
end

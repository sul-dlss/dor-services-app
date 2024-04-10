# frozen_string_literal: true

module Migrators
  # Migrator that will be used to remove release tags.
  class RemoveReleaseTags < Base
    def migrate?
      (ar_cocina_object.is_a?(Dro) || ar_cocina_object.is_a?(Collection)) && ar_cocina_object.administrative.key?('releaseTags')
    end

    def migrate
      ar_cocina_object.administrative.delete('releaseTags')
    end
  end
end

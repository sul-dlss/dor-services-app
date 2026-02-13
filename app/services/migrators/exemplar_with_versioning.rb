# frozen_string_literal: true

module Migrators
  # An extension of the most basic exemplar, meant for the :migrate
  # mode, and testing of the versioning option.
  class ExemplarWithVersioning < Exemplar
    def version?
      true
    end

    def version_description
      'this is a new version for testing the cocina migration runner'
    end
  end
end

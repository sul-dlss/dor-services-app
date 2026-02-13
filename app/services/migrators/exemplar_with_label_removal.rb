# frozen_string_literal: true

module Migrators
  # An extension of the most basic exemplar, meant for the :migrate
  # mode, and testing that updating the object with invalid cocina
  # raises an error.
  class ExemplarWithLabelRemoval < Exemplar
    def migrate
      head_rov.label = nil
      head_rov.description['title'].first['value'] = nil
    end
  end
end

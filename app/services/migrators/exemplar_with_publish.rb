# frozen_string_literal: true

module Migrators
  # An extension of the most basic exemplar, meant for the :migrate
  # mode, and testing of the publishing option.
  class ExemplarWithPublish < Exemplar
    def publish?
      true
    end
  end
end

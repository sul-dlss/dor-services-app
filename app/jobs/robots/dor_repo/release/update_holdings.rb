# frozen_string_literal: true

module Robots
  module DorRepo
    module Release
      # Update/create FOLIO holdings record for an object
      class UpdateHoldings < Robots::Robot
        def initialize
          super('releaseWF', 'update-holdings')
        end

        def perform_work
          Catalog::UpdateHoldingsService.update(cocina_object)
        end
      end
    end
  end
end

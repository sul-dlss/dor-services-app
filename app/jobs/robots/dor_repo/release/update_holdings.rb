# frozen_string_literal: true

module Robots
  module DorRepo
    module Release
      # Update/create FOLIO holdings record for an object
      class UpdateHoldings < Robots::Robot
        def initialize
          super('releaseWF', 'update-holdings', retriable_exceptions: [RedisLock::DeadLockError])
        end

        def perform_work
          return if cocina_object.admin_policy?
          return if folio_hrid.nil?

          raise RedisLock::DeadLockError unless RedisLock.with_lock(key: "update-holdings-#{folio_hrid}",
                                                                    lock_timeout: 180) do
            Catalog::UpdateHoldingsService.update(cocina_object)
          end
        end

        def folio_hrid
          @folio_hrid ||= cocina_object.identification.catalogLinks.find do |link|
            link.catalog == 'folio'
          end&.catalogRecordId
        end
      end
    end
  end
end

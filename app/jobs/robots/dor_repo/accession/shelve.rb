# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Push file changes for shelve-able files into stacks
      class Shelve < Robots::Robot
        def initialize
          super('accessionWF', 'shelve')
        end

        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'Not a WAS crawl, nothing to do') unless cocina_object.dro? && WasService.crawl?(druid: druid)

          WasShelvingService.shelve(cocina_object)

          # Shelving can take a long time and can cause the database connections to get stale.
          # So reset to avoid: ActiveRecord::StatementInvalid: PG::ConnectionBad: PQconsumeInput() could not receive data from server: Connection timed out : BEGIN
          ActiveRecord::Base.connection_handler.clear_active_connections!
          EventFactory.create(druid:, event_type: 'shelving_complete', data: {})
        end
      end
    end
  end
end

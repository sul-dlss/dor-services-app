# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Initiate releaseWF.
      class ReleaseInitiate < Robots::Robot
        def initialize
          super('accessionWF', 'release-initiate')
        end

        def perform_work
          if cocina_object.admin_policy?
            return LyberCore::ReturnState.new(status: :skipped,
                                              note: 'Admin policy objects are not released')
          end

          Workflow::Service.create(druid:, workflow_name: 'releaseWF',
                                   version: cocina_object.version)
        end
      end
    end
  end
end

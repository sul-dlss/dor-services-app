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

          if skipped?
            return LyberCore::ReturnState.new(status: :skipped,
                                              note: 'releaseWF was skipped because workflow context indicated this')
          end

          Workflow::Service.create(druid:, workflow_name: 'releaseWF',
                                   version: cocina_object.version)
        end

        def skipped?
          # checks if user has indicated that releaseWF should be skipped (sent as workflow_context)
          # default to false if not present
          workflow.context['skipReleaseWF'] || false
        end
      end
    end
  end
end

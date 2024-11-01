# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Transfers the object to preservation
      class SdrIngestTransfer < Robots::Robot
        def initialize
          # VersionMismatchError may be caused by storage latency, so retrying.
          super('accessionWF', 'sdr-ingest-transfer', retriable_exceptions: [PreservationIngestService::VersionMismatchError])
        end

        def perform_work
          PreservationIngestService.transfer(cocina_object) # This might raise a StandardError which will be handled by the retry above.

          # start SDR preservation workflow
          workflow_service.create_workflow_by_name(druid, 'preservationIngestWF', version: cocina_object.version, lane_id:)
        end
      end
    end
  end
end

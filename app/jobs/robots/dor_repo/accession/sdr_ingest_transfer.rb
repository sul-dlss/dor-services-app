# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Transfers the object to preservation
      class SdrIngestTransfer < Robots::Robot
        def initialize
          # VersionMismatchError may be caused by storage latency, so retrying.
          super('accessionWF', 'sdr-ingest-transfer',
          retriable_exceptions: [PreservationIngestService::VersionMismatchError])
        end

        def perform_work
          # This might raise a StandardError which will be handled by the retry above.
          PreservationIngestService.transfer(cocina_object)

          # start SDR preservation workflow
          Workflow::Service.create(druid:, workflow_name: 'preservationIngestWF', version: cocina_object.version,
                                   lane_id:)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Robots
  module DorRepo
    module Release
      # Start the release workflow for an object
      class Start < Robots::Robot
        def initialize
          super('releaseWF', 'start')
        end

        def perform_work
          # If the cocina_object is not associated with an HRID or a previous HRID
          # then mark the Folio steps as skipped.
          return if cocina_object.identification.catalogLinks.any?(Cocina::Models::FolioCatalogLink)

          Workflow::ProcessService.update(druid:, workflow_name:, process: 'update-marc', status: 'skipped')
          Workflow::ProcessService.update(druid:, workflow_name:, process: 'update-holdings', status: 'skipped')
        end
      end
    end
  end
end

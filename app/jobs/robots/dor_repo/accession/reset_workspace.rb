# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # This takes link for the object in the /dor/workspace directory and renames it so it has a version number.
      # It also cleans up the workspace directory.
      # (i.e. /dor/assembly/xw/754/sd/7436/xw754sd7436/ -> /dor/assembly/xw/754/sd/7436/xw754sd7436_v2/)
      class ResetWorkspace < Robots::Robot
        def initialize
          super('accessionWF', 'reset-workspace')
        end

        def perform_work
          CleanupService.cleanup_by_druid druid

          EventFactory.create(druid:,
                              event_type: 'cleanup-workspace',
                              data: { status: 'success' })
        rescue Errno::ENOENT, Errno::ENOTEMPTY => e
          EventFactory.create(druid:, event_type: 'cleanup-workspace',
                              data: { status: 'failure', message: e.message })
          raise
        end
      end
    end
  end
end

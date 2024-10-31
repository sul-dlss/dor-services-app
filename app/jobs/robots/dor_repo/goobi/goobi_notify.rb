# frozen_string_literal: true

module Robots
  module DorRepo
    module Goobi
      # Notifies Goobi that an object is ready for processing
      class GoobiNotify < Robots::Robot
        def initialize
          super('goobiWF', 'goobi-notify')
        end

        def perform_work
          response = GoobiService.register(cocina_object)
          raise "Unexpected response from Goobi (#{response.status}): #{response.body}" unless response.success?
        end
      end
    end
  end
end

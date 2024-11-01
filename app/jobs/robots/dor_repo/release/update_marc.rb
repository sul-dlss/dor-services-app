# frozen_string_literal: true

module Robots
  module DorRepo
    module Release
      # Update MARC record for an object
      class UpdateMarc < Robots::Robot
        def initialize
          super('releaseWF', 'update-marc')
        end

        def perform_work
          Catalog::UpdateMarc856RecordService.update(cocina_object, thumbnail_service: ThumbnailService.new(cocina_object))
        end
      end
    end
  end
end

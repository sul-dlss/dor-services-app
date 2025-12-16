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
          # temporarily skip update-marc step during winter closure 2025, post-FOLIO update
          # to be reverted Jan 5, 2026
          LyberCore::ReturnState.new(status: :skipped,
                                     note: 'Skipping during FOLIO update winter closure 2025')
          # Catalog::UpdateMarc856RecordService.update(cocina_object,
          #                                            thumbnail_service: ThumbnailService.new(cocina_object))
        end
      end
    end
  end
end

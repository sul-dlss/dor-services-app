# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Publishing metadata and shelving files for object.
      class Publish < Robots::Robot
        def initialize
          super('accessionWF', 'publish', retriable_exceptions: [PurlFetcher::Client::Error])
        end

        def perform_work
          if cocina_object.admin_policy?
            return LyberCore::ReturnState.new(status: :skipped,
                                              note: 'Admin policy objects are not published')
          end

          ::Publish::MetadataTransferService.publish(druid:)
          EventFactory.create(druid:, event_type: 'publishing_complete', data: {})
        end
      end
    end
  end
end

module Robots
  module DorRepo
    module Accession
      # Sends initial metadata to PURL, in robots/release/release_publish we push
      # to PURL again with updates to identityMetadata
      class Publish < LyberCore::Robot
        def initialize
          super('accessionWF', 'publish')
        end

        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'Admin policy objects are not published') if cocina_object.admin_policy?

          # # Calls asynchronous process, which will set the publish workflow step to complete when it is done.
          # object_client.publish(workflow: 'accessionWF', lane_id:)
          # LyberCore::ReturnState.new(status: :noop, note: 'Initiated publish API call.')
          result = BackgroundJobResult.create
          PublishJob.set(queue: publish_queue).perform_later(druid:, background_job_result: result, workflow: 'accessionWF')
        end
      end
    end
  end
end

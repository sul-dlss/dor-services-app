# frozen_string_literal: true

# Update the BackgroundJobResult and alert the workflow service
# This is done as a separate job so that if the work is complete, but there is an
# error writing this data, we don't have to re-do the work.
class StartPreservationWorkflowJob < ApplicationJob
  queue_as :default

  # @param [String] druid the identifier of the item to be published
  # @param [String] version the current version of the item to be published
  # @param [BackgroundJobResult] background_job_result identifier of a background job result to store status info
  def perform(druid:, version:, background_job_result:)
    lane_id = client.process(pid: druid, workflow_name: 'accessionWF', process: 'sdr-ingest-transfer').lane_id
    # start SDR preservation workflow
    client.create_workflow_by_name(druid, 'preservationIngestWF', version: version, lane_id: lane_id)

    LogSuccessJob.perform_later(druid: druid,
                                workflow: 'accessionWF',
                                background_job_result: background_job_result,
                                workflow_process: 'sdr-ingest-transfer')
  end

  private

  def client
    WorkflowClientFactory.build
  end
end

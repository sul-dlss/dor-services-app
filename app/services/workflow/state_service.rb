# frozen_string_literal: true

module Workflow
  # Queries the workflow state of an object for a specific version.
  # This is primarily intended to support versioning.
  class StateService
    def self.accessioning?(...)
      new(...).accessioning?
    end

    def self.accessioned?(...)
      new(...).accessioned?
    end

    def initialize(druid:, version:)
      @druid = druid
      @version = version
    end

    # Checks if the latest version has any assembly workflows with incomplete steps.
    # @return [Boolean] true if object is currently being assembled
    def assembling?
      @assembling ||= workflow_state_batch_service.assembling_druids.include?(druid)
    end

    # Checks if the active (latest) version has any incomplete workflow steps in accessionWF (other than end-accession).
    # We allow end-accession to be incomplete, because we want to be able to open a new version from other workflows,
    # such as ocrWF, without being blocked by a race condition (i.e. end-accession is still not marked as complete)
    # If there are other active steps in accessionWF, we don't want to start another accession workflow.
    # Note that this is also true if a preservationAuditWF or preservationIngestWF has returned an error,
    # because it will not complete the `sdr-ingest-received` step, which will cause this to return true as well.
    # @return [Boolean] true if object is currently being accessioned or is failing an audit
    def accessioning?
      @accessioning ||= workflow_state_batch_service.accessioning_druids.include?(druid)
    end

    # @return [Boolean] true if the object has previously been accessioned.
    def accessioned?
      @accessioned ||= workflow_state_batch_service.accessioned_druids.include?(druid)
    end

    private

    attr_reader :druid, :version

    def workflow_state_batch_service
      @workflow_state_batch_service ||= Workflow::StateBatchService.new(druids: [druid])
    end
  end
end

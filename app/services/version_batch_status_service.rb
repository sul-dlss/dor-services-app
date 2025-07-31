# frozen_string_literal: true

# Service for retrieving the version status of a batch of objects.
class VersionBatchStatusService
  # This isn't a Workflow::StateService, but it acts like one.
  DummyWorkflowStateService = Struct.new('DummyWorkflowStateService', :accessioning, :accessioned, :assembling) do
    def accessioning?
      accessioning
    end

    def accessioned?
      accessioned
    end

    def assembling?
      assembling
    end
  end

  def self.call(...)
    new(...).call
  end

  # raises CocinaObjectStore::CocinaObjectNotFoundError if the druid is not found
  def self.call_single(druid:)
    new(druids: [druid]).call.fetch(druid, nil).tap do |status|
      raise CocinaObjectStore::CocinaObjectNotFoundError, 'Object not found' unless status
    end
  end

  def initialize(druids:, limit: nil)
    @druids = druids
    @limit = limit
  end

  # @return [Hash<String, Hash>] map of druid to status hash
  def call
    druids.filter_map do |druid|
      status = status_for(druid)
      next unless status

      [druid, status]
    end.to_h
  end

  private

  attr_reader :druids, :limit

  # rubocop:disable Metrics/MethodLength, Layout/LineLength
  def repository_object_map
    @repository_object_map ||= RepositoryObject
                               .joins('INNER JOIN repository_object_versions AS head_version ON repository_objects.head_version_id = head_version.id')
                               .joins('LEFT OUTER JOIN repository_object_versions AS opened_version ON repository_objects.opened_version_id = opened_version.id')
                               .joins('LEFT OUTER JOIN repository_object_versions AS last_closed_version ON repository_objects.last_closed_version_id = last_closed_version.id')
                               .select(
                                 'repository_objects.external_identifier',
                                 'repository_objects.id',
                                 'repository_objects.head_version_id',
                                 'repository_objects.opened_version_id',
                                 'repository_objects.last_closed_version_id',
                                 'opened_version.version AS opened_version_version',
                                 'opened_version.version_description AS opened_version_version_description',
                                 'last_closed_version.version AS last_closed_version_version',
                                 'last_closed_version.version_description AS last_closed_version_version_description',
                                 'head_version.version AS head_version_version',
                                 'head_version.version_description AS head_version_version_description'
                               )
                               .where(external_identifier: druids)
                               .limit(limit)
                               .index_by(&:external_identifier)
  end
  # rubocop:enable Metrics/MethodLength, Layout/LineLength

  def accessioning_druids
    @accessioning_druids ||= workflow_state_batch_service.accessioning_druids
  end

  def accessioned_druids
    @accessioned_druids ||= workflow_state_batch_service.accessioned_druids
  end

  def assembling_druids
    # For any of the assembly workflows, are they are incomplete workflow steps for the active version,
    # ignoring certain final steps that might not be complete yet.
    @assembling_druids ||= workflow_state_batch_service.assembling_druids
  end

  def status_for(druid)
    repository_object = repository_object_map[druid]
    return unless repository_object

    version = repository_object.head_version_version
    workflow_state_service = workflow_state_service_for(druid)
    version_service = VersionService.new(druid:, version:, workflow_state_service:, repository_object:)

    {
      versionId: version,
      open: version_service.open?,
      # checks workflow state service accessioned?, accessioning?
      openable: version_service.can_open?(check_preservation: false),
      assembling: workflow_state_service.assembling?,
      accessioning: workflow_state_service.accessioning?,
      # checks workflow state assembling?, accessioning?
      closeable: version_service.can_close?,
      discardable: version_service.can_discard?,
      versionDescription: repository_object.head_version_version_description
    }
  end

  def workflow_state_service_for(druid)
    DummyWorkflowStateService.new(
      accessioning: accessioning_druids.include?(druid),
      accessioned: accessioned_druids.include?(druid),
      assembling: assembling_druids.include?(druid)
    )
  end

  def workflow_state_batch_service
    @workflow_state_batch_service ||= Workflow::StateBatchService.new(druids:)
  end
end

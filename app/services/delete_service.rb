# frozen_string_literal: true

# Remove all traces of the object's data files from the workspace and export areas
class DeleteService
  # Tries to remove any existence of the object in our systems
  #   Does the following:
  #   - Removes content from dor workspace
  #   - Removes content from assembly workspace
  #   - Removes content from sdr export area
  #   - Removes content from stacks
  #   - Removes content from purl
  #   - Removes active workflows
  # @param [Cocina::Models::DRO|AdminPolicy||Collection] cocina object wish to remove
  def self.destroy(cocina_object, user_name:, event_factory: EventFactory)
    new(cocina_object, user_name, event_factory).destroy
  end

  def initialize(cocina_object, user_name, event_factory)
    @cocina_object = Cocina::Models.without_metadata(cocina_object)
    @user_name = user_name
    @event_factory = event_factory
  end

  def destroy
    CleanupService.cleanup_by_druid druid
    cleanup_stacks
    cleanup_purl_doc_cache
    remove_active_workflows
    delete_from_dor
    event_factory.create(druid:, event_type: 'delete', data: { request: cocina_object.to_h, source_id: cocina_object&.identification&.sourceId, user_name: })
  end

  private

  attr_reader :cocina_object, :event_factory, :user_name

  def cleanup_stacks
    stacks_druid = DruidTools::StacksDruid.new(druid, Settings.stacks.local_stacks_root)
    PruneService.new(druid: stacks_druid).prune!
  end

  def cleanup_purl_doc_cache
    purl_druid = DruidTools::PurlDruid.new(druid, Settings.stacks.local_document_cache_root)
    PruneService.new(druid: purl_druid).prune!
  end

  def remove_active_workflows
    WorkflowClientFactory.build.delete_all_workflows(pid: druid)
  end

  # Delete an object from DOR.
  def delete_from_dor
    CocinaObjectStore.destroy(druid)
    AdministrativeTags.destroy_all(identifier: druid)
    ObjectVersion.where(druid:).destroy_all
    Event.where(druid:).destroy_all
    ReleaseTag.where(druid:).destroy_all
  end

  def druid
    @druid ||= cocina_object.externalIdentifier
  end
end

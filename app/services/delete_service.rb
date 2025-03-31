# frozen_string_literal: true

# Remove all traces of the object's data files from the workspace and export areas
class DeleteService
  # Tries to remove any existence of the object in our systems
  #   Does the following:
  #   - Removes content from dor workspace
  #   - Removes content from assembly workspace
  #   - Removes content from sdr export area
  #   - Removes active workflows
  # @param [Cocina::Models::DRO|AdminPolicy||Collection] cocina object wish to remove
  def self.destroy(cocina_object, user_name:)
    new(cocina_object, user_name).destroy
  end

  def initialize(cocina_object, user_name)
    @cocina_object = Cocina::Models.without_metadata(cocina_object)
    @user_name = user_name
  end

  def destroy
    CleanupService.cleanup_by_druid druid
    remove_active_workflows
    delete_from_dor
    EventFactory.create(druid:, event_type: 'delete',
                        data: { request: cocina_object.to_h, source_id: cocina_object&.identification&.sourceId,
                                user_name: })
  end

  private

  attr_reader :cocina_object, :user_name

  def remove_active_workflows
    WorkflowClientFactory.build.delete_all_workflows(pid: druid)
  end

  # Delete an object from DOR.
  def delete_from_dor
    RepositoryObject.transaction do
      RepositoryObject.find_by!(external_identifier: druid).destroy
      AdministrativeTags.destroy_all(identifier: druid)
      Event.where(druid:).destroy_all
      ReleaseTag.where(druid:).destroy_all
    end
    Indexer.delete(druid:)
  end

  def druid
    @druid ||= cocina_object.externalIdentifier
  end
end

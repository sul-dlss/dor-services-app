# frozen_string_literal: true

# Remove all traces of the object's data files from the workspace and export areas
class DeleteService
  # Tries to remove any existence of the object in our systems
  #   Does the following:
  #   - Removes item from Fedora/Solr
  #   - Removes content from dor workspace
  #   - Removes content from assembly workspace
  #   - Removes content from sdr export area
  #   - Removes content from stacks
  #   - Removes content from purl
  #   - Removes active workflows
  # @param [String] druid id of the object you wish to remove
  def self.destroy(druid)
    new(druid).destroy
  end

  def initialize(druid)
    @druid = druid
  end

  def destroy
    CleanupService.cleanup_by_druid druid
    cleanup_stacks
    cleanup_purl_doc_cache
    remove_active_workflows
    delete_from_dor
  end

  private

  attr_reader :druid

  def cleanup_stacks
    stacks_druid = DruidTools::StacksDruid.new(druid, Dor::Config.stacks.local_stacks_root)
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
  #
  # @param [string] pid the druid
  def delete_from_dor
    ActiveFedora::Base.connection_for_pid(0).api.purge_object(pid: druid)
    ActiveFedora::SolrService.instance.conn.delete_by_id(druid)
    ActiveFedora::SolrService.instance.conn.commit
  end
end

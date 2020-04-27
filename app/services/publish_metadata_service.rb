# frozen_string_literal: true

# Merges contentMetadata from several objects into one and sends it to PURL
class PublishMetadataService
  # @param [Dor::Item] item the object to be publshed
  def self.publish(item)
    new(item).publish
  end

  def initialize(item)
    @item = item
  end

  # Appends contentMetadata file resources from the source objects to this object
  # @raise [Dor::DataError]
  def publish
    return unpublish unless world_discoverable?

    # Retrieve release tags from identityMetadata and all collections this item is a member of
    release_tags = ReleaseTags.for(item: item)

    transfer_metadata(release_tags)
    bookkeep_collections
    publish_notify_on_success
  end

  private

  attr_reader :item

  # @raise [Dor::DataError]
  def transfer_metadata(release_tags)
    transfer_to_document_store(DublinCoreService.new(item).ng_xml.to_xml(&:no_declaration), 'dc')
    %w[identityMetadata contentMetadata rightsMetadata].each do |stream|
      transfer_to_document_store(item.datastreams[stream].content.to_s, stream) if item.datastreams[stream]
    end
    transfer_to_document_store(PublicXmlService.new(item, released_for: release_tags).to_xml, 'public')
    transfer_to_document_store(PublicDescMetadataService.new(item).to_xml, 'mods')
  end

  # Maintain bidirectional symlinks from:
  #  - an item to the collections it belongs to
  #  - a collection to the items within
  def bookkeep_collections
    FileUtils.mkdir_p(item_collections_dir)
    existing_collections = Dir.children(item_collections_dir)

    # Write bidirectional symlinks for collection membership
    item.collections.each do |coll|
      Rails.logger.debug("[Publish][#{item.pid}] Adding collection association with #{coll.pid}")
      collection_items_dir = collection_member_dir(coll.pid)
      FileUtils.mkdir_p(collection_items_dir)
      FileUtils.ln_s(item.content_dir, File.join(collection_items_dir, local_part(item.pid)), force: true)
      FileUtils.ln_s(coll.content_dir, File.join(item_collections_dir, local_part(coll.pid)), force: true)
    end

    # Remove bidirectional collection membership for collections no longer asserted
    (existing_collections - item.collections.map { |coll| local_part(coll.pid) }).each do |coll_pid|
      Rails.logger.debug("[Publish][#{item.pid}] Removing collection association with #{coll_pid}")
      FileUtils.rm(File.join(item_collections_dir, coll_pid), force: true)

      collection_items_dir = collection_member_dir(coll_pid)
      next unless Dir.exist? collection_items_dir

      FileUtils.rm(File.join(collection_items_dir, local_part(item.pid)), force: true)
    end
  end

  # Remove all collection membership symlinks
  def unbookkeep_collections
    return unless Dir.exist? item_collections_dir

    existing_collections = Dir.children(item_collections_dir)
    existing_collections.each do |coll_pid|
      collection_items_dir = collection_member_dir(coll_pid)
      next unless Dir.exist? collection_items_dir

      FileUtils.rm(File.join(collection_items_dir, local_part(item.pid)))
    end

    members_dir = collection_member_dir(item.pid)
    if Dir.exist? members_dir
      existing_members = Dir.children(members_dir)
      existing_members.each do |item_pid|
        item_dir = item_collections_dir(item_pid)
        next unless Dir.exist? item_dir

        FileUtils.rm(File.join(item_dir, local_part(item.pid)))
      end
    end
  end

  # Clear out the document cache for this item
  def unpublish
    unbookkeep_collections
    PruneService.new(druid: purl_druid).prune!
    publish_delete_on_success
  end

  def world_discoverable?
    rights = item.rightsMetadata.ng_xml.clone.remove_namespaces!
    rights.at_xpath("//rightsMetadata/access[@type='discover']/machine/world")
  end

  # Create a file inside the content directory under the stacks.local_document_cache_root
  # @param [String] content The contents of the file to be created
  # @param [String] filename The name of the file to be created
  # @return [void]
  def transfer_to_document_store(content, filename)
    new_file = File.join(purl_druid.content_dir, filename)
    Rails.logger.debug("[Publish][#{item.pid}] Writing #{new_file}")
    File.open(new_file, 'w') { |f| f.write content }
  end

  def purl_druid
    @purl_druid ||= DruidTools::PurlDruid.new item.pid, Settings.stacks.local_document_cache_root
  end

  # Get the collection membership directory for an item
  def item_collections_dir(item_pid = nil)
    item_druid = if item_pid
      DruidTools::PurlDruid.new item_pid, Settings.stacks.local_document_cache_root
    else
      purl_druid
    end

    File.join(item_druid.content_dir, 'is_member_of_collection')
  end

  # Get the collection members directory for a collection
  def collection_member_dir(collection_pid)
    collection_druid = DruidTools::PurlDruid.new collection_pid, Settings.stacks.local_document_cache_root
    File.join(collection_druid.content_dir, 'has_member_of_collection')
  end


  ##
  # When publishing a PURL, we notify purl-fetcher of changes.
  #
  def publish_notify_on_success
    Faraday.post(purl_services_url)
  end

  ##
  # When deleting a PURL, we notify purl-fetcher of changes.
  #
  def publish_delete_on_success
    Faraday.delete(purl_services_url)
  end

  def purl_services_url
    raise 'You have not configured perl-fetcher (Settings.purl_services_url).' unless Settings.purl_services_url

    "#{Settings.purl_services_url}/purls/#{local_part(item.pid)}"
  end

  def local_part(pid)
    Dor::PidUtils.remove_druid_prefix(pid)
  end
end

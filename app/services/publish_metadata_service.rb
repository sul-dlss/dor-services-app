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
  # @raises [Dor::DataError]
  def publish
    return unpublish unless world_discoverable?

    transfer_metadata
    publish_notify_on_success
  end

  private

  attr_reader :item

  # @raises [Dor::DataError]
  def transfer_metadata
    transfer_to_document_store(DublinCoreService.new(item).ng_xml.to_xml(&:no_declaration), 'dc')
    %w[identityMetadata contentMetadata rightsMetadata].each do |stream|
      transfer_to_document_store(item.datastreams[stream].content.to_s, stream) if item.datastreams[stream]
    end
    # Retrieve release tags from metadata and PURL
    released_for = Dor::ReleaseTagService.for(item).released_for(skip_live_purl: false)
    transfer_to_document_store(PublicXmlService.new(item, released_for: released_for).to_xml, 'public')
    transfer_to_document_store(PublicDescMetadataService.new(item).to_xml, 'mods')
  end

  # Clear out the document cache for this item
  def unpublish
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
    File.open(new_file, 'w') { |f| f.write content }
  end

  def purl_druid
    @purl_druid ||= DruidTools::PurlDruid.new item.pid, Settings.stacks.local_document_cache_root
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
    id = item.pid.gsub(/^druid:/, '')

    raise 'You have not configured perl-fetcher (Settings.purl_services_url).' unless Settings.purl_services_url

    "#{Settings.purl_services_url}/purls/#{id}"
  end
end

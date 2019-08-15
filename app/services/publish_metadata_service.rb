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
  def publish
    return unpublish unless world_discoverable?

    transfer_metadata
    publish_notify_on_success
  end

  private

  attr_reader :item

  def transfer_metadata
    transfer_to_document_store(DublinCoreService.new(item).ng_xml.to_xml(&:no_declaration), 'dc')
    %w[identityMetadata contentMetadata rightsMetadata].each do |stream|
      transfer_to_document_store(item.datastreams[stream].content.to_s, stream) if item.datastreams[stream]
    end
    transfer_to_document_store(PublicXmlService.new(item).to_xml, 'public')
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
    id = item.pid.gsub(/^druid:/, '')

    rest_client["purls/#{id}"].post ''
  end

  ##
  # When deleting a PURL, we notify purl-fetcher of changes.
  #
  def publish_delete_on_success
    id = item.pid.gsub(/^druid:/, '')

    rest_client["purls/#{id}"].delete
  end

  def rest_client
    raise 'You have not configured perl-fetcher (Settings.purl_services_url).' unless Settings.purl_services_url

    RestClient::Resource.new(Settings.purl_services_url)
  end
end

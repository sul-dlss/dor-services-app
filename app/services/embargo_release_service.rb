# frozen_string_literal: true

# Finds objects where the embargo release date has passed for embargoed items
# Builds list of candidate objects by doing a Solr query
#
# Should run once a day from cron
class EmbargoReleaseService
  RELEASEABLE_NOW_QUERY = 'embargo_status_ssim:"embargoed" AND embargo_release_dtsim:[* TO NOW]'
  TWENTY_PERCENT_RELEASEABLE_NOW_QUERY = 'twenty_pct_status_ssim:"embargoed" AND twenty_pct_release_embargo_release_dtsim:[* TO NOW]'

  # Finds druids from solr based on the passed in query
  # It will then load each item from Dor, and call the block with the item
  # @param [String] query used to locate druids of items to release from solr
  # @param [String] embargo_msg embargo type used in log messages (embargo vs 20% visibilty embargo)
  # @yield [Dor::Item] gets executed after loading the object from DOR and opening new version
  #  Steps needed to release the particular embargo from the item
  def self.release_items(query, embargo_msg = 'embargo', &release_block)
    # Find objects to process
    Rails.logger.info("***** Querying solr: #{query}")
    solr = Dor::SearchService.query(query, 'rows' => '5000', 'fl' => 'id')

    num_found = solr['response']['numFound'].to_i
    if num_found.zero?
      Rails.logger.info('No objects to process')
      return
    end
    Rails.logger.info("Found #{num_found} objects")

    count = 0
    solr['response']['docs'].each do |doc|
      release_item(doc['id'], embargo_msg, &release_block)
      count += 1
    end

    Rails.logger.info("Done! Processed #{count} objects out of #{num_found}")
  end

  def self.release_item(druid, embargo_msg, &release_block)
    ei = Dor.find(druid)
    unless WorkflowClientFactory.build.lifecycle(druid: druid, milestone_name: 'accessioned')
      Rails.logger.warn("Skipping #{druid} - not yet accessioned")
      return
    end

    unless VersionService.can_open?(ei)
      Rails.logger.warn("Skipping #{druid} - object is already open")
      return
    end

    Rails.logger.info("Releasing #{embargo_msg} for #{druid}")

    VersionService.open(ei, event_factory: EventFactory)
    release_block.call(ei)
    ei.save!
    VersionService.close(ei, { description: "#{embargo_msg} released", significance: 'admin' }, event_factory: EventFactory)
  rescue StandardError => e
    Rails.logger.error("!!! Unable to release embargo for: #{druid}\n#{e.inspect}\n#{e.backtrace.join("\n")}")
    Honeybadger.notify "Unable to release embargo for: #{druid}", backtrace: e.backtrace
  end

  def self.release_all
    release_items(RELEASEABLE_NOW_QUERY) do |item|
      new(item).release('application:accessionWF:embargo-release')
    end

    release_items(TWENTY_PERCENT_RELEASEABLE_NOW_QUERY, '20% visibility embargo') do |item|
      new(item).release_20_pct_vis('application:accessionWF:embargo-release')
    end
  end

  # @param [Dor::Item] item
  def initialize(item)
    @item = item
  end

  # Lift the embargo from the object
  # Sets embargo status to released in embargoMetadata
  # Modifies rightsMetadata to remove embargoReleaseDate and updates/adds access from embargoMetadata/releaseAccess
  # @param [String] release_agent name of the person, application or thing that released embargo
  # @note The caller should save the object to fedora to commit the changes
  def release(release_agent)
    # Set status to released
    embargoMetadata.status = 'released'

    # Remove all read acces nodes
    rights_xml = rightsMetadata.ng_xml
    rightsMetadata.ng_xml_will_change!
    rights_xml.xpath("//rightsMetadata/access[@type='read']").each(&:remove)

    # Replace rights <access> nodes with those from embargoMetadta
    release_access = embargoMetadata.release_access_node
    release_access.xpath('//releaseAccess/access').each do |new_access|
      access_sibling = rights_xml.at_xpath('//rightsMetadata/access[last()]')
      if access_sibling
        access_sibling.add_next_sibling(new_access.clone)
      else
        rights_xml.root.add_child(new_access.clone)
      end
    end

    events.add_event('embargo', release_agent, 'Embargo released')
  end

  def release_20_pct_vis(release_agent)
    # Set status to released
    embargoMetadata.twenty_pct_status = 'released'

    # Remove all read acces nodes
    rights_xml = rightsMetadata.ng_xml
    rightsMetadata.ng_xml_will_change!
    rights_xml.xpath("//rightsMetadata/access[@type='read']").each(&:remove)

    # Replace rights <access> nodes with 1 machine/world node
    access_sibling = rights_xml.at_xpath('//rightsMetadata/access[last()]')
    if access_sibling
      access_sibling.add_next_sibling(world_doc.root.clone)
    else
      rights_xml.root.add_child(world_doc.root.clone)
    end

    events.add_event('embargo', release_agent, '20% Visibility Embargo released')
  end

  private

  attr_reader :item

  delegate :rightsMetadata, :embargoMetadata, :events, to: :item

  def world_doc
    Nokogiri::XML::Builder.new do |xml|
      xml.access(type: 'read') do
        xml.machine { xml.world }
      end
    end.doc
  end
end

# frozen_string_literal: true

# Finds objects where the embargo release date has passed for embargoed items
# Builds list of candidate objects by doing a Solr query
#
# Should run once a day from cron
class EmbargoReleaseService
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
    unless WorkflowClientFactory.build.lifecycle('dor', druid, 'accessioned')
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

  def self.release
    release_items('embargo_status_ssim:"embargoed" AND embargo_release_dtsim:[* TO NOW]') do |item|
      Dor::EmbargoService.new(item).release_embargo('application:accessionWF:embargo-release')
    end

    release_items('twenty_pct_status_ssim:"embargoed" AND twenty_pct_visibility_release_dtsim:[* TO NOW]',
                  '20% visibility embargo') do |item|
      Dor::EmbargoService.new(item).release_20_pct_vis_embargo('application:accessionWF:embargo-release')
    end
  end
end

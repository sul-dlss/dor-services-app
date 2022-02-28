# frozen_string_literal: true

# Finds objects where the embargo release date has passed for embargoed items
# Builds list of candidate objects by doing a Solr query
#
# Should run once a day from cron
class EmbargoReleaseService
  RELEASEABLE_NOW_QUERY = 'embargo_status_ssim:"embargoed" AND embargo_release_dtsim:[* TO NOW]'

  # Finds druids from solr based on the passed in query
  # It will then load each item from Dor, and call the block with the item
  # @param [String] query used to locate druids of items to release from solr
  # @yield [Cocina::Models::DRO] gets executed after loading the object from DOR and opening new version
  #  Steps needed to release the particular embargo from the item
  def self.release_items(query, &release_block)
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
      release_item(doc['id'], &release_block)
      count += 1
    end

    Rails.logger.info("Done! Processed #{count} objects out of #{num_found}")
  end

  def self.release_all
    # Find objects to process
    Rails.logger.info("***** Querying solr: #{RELEASEABLE_NOW_QUERY}")
    solr = Dor::SearchService.query(RELEASEABLE_NOW_QUERY, 'rows' => '5000', 'fl' => 'id')

    num_found = solr['response']['numFound'].to_i
    if num_found.zero?
      Rails.logger.info('No objects to process')
      return
    end
    Rails.logger.info("Found #{num_found} objects")

    count = 0
    solr['response']['docs'].each do |doc|
      release(doc['id'])
      count += 1
    end

    Rails.logger.info("Done! Processed #{count} objects out of #{num_found}")
  end

  def self.release(druid)
    new(druid).release
  end

  # @param [druid] druid
  def initialize(druid)
    @druid = druid
  end

  def release
    unless WorkflowClientFactory.build.lifecycle(druid: druid, milestone_name: 'accessioned')
      Rails.logger.warn("Skipping #{druid} - not yet accessioned")
      return
    end

    unless VersionService.can_open?(cocina_object)
      Rails.logger.warn("Skipping #{druid} - object is already open")
      return
    end
    Rails.logger.info("Releasing embargo for #{druid}")

    updated_cocina_object = VersionService.open(cocina_object, event_factory: EventFactory)

    updated_cocina_object = release_cocina_object(updated_cocina_object)

    VersionService.close(updated_cocina_object, { description: 'embargo released', significance: 'admin' }, event_factory: EventFactory)

    EventFactory.create(druid: druid, event_type: 'embargo_released', data: {})

    # Broadcast this action to a topic
    Notifications::EmbargoLifted.publish(model: updated_cocina_object)
  rescue StandardError => e
    Rails.logger.error("!!! Unable to release embargo for: #{druid}\n#{e.inspect}\n#{e.backtrace.join("\n")}")
    Honeybadger.notify "Unable to release embargo for: #{druid}", backtrace: e.backtrace
  end

  private

  attr_reader :druid

  def release_cocina_object(cocina_object)
    access_props = access_props_for(cocina_object)

    structural_props = structural_props_for(cocina_object, access_props)

    CocinaObjectStore.save(cocina_object.new({ access: access_props, structural: structural_props }.compact))
  end

  def access_props_for(cocina_object)
    # Copy access > embargo > useAndReproductionStatement, access, download, readLocation, controlledDigitalLending to access >
    # Remove access > embargo
    access_props = cocina_object.access.to_h.except(:access, :download, :readLocation, :controlledDigitalLending, :useAndReproductionStatement)
    access_props.merge!(access_props[:embargo].except(:releaseDate))
    # Remove embargo
    access_props.delete(:embargo)
    access_props
  end

  def structural_props_for(cocina_object, access_props)
    return nil if cocina_object.structural.nil?

    # Apply access to files
    file_access_props = access_props.slice(:access, :download, :readLocation, :controlledDigitalLending)
    file_access_props[:access] = 'dark' if file_access_props[:access] == 'citation-only'

    structural_props = cocina_object.structural.to_h
    Array(structural_props[:contains]).each do |file_set_props|
      Array(file_set_props.dig(:structural, :contains)).each do |file_props|
        file_props[:access] = file_access_props
      end
    end
    structural_props
  end

  def cocina_object
    @cocina_object ||= CocinaObjectStore.find(druid)
  end
end

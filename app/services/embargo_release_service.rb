# frozen_string_literal: true

# Finds objects where the embargo release date has passed for embargoed items
# Builds list of candidate objects by querying the database
#
# Should run once a day from cron
class EmbargoReleaseService
  def self.release_all
    # Find objects to process
    embargoed_items_to_release = Dro.embargoed_and_releaseable

    if embargoed_items_to_release.none?
      Rails.logger.info('No objects to process')
      return
    end
    Rails.logger.info("Found #{embargoed_items_to_release.count} objects")

    count = 0
    embargoed_items_to_release.each do |item|
      release(item.external_identifier)
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
    unless WorkflowClientFactory.build.lifecycle(druid:, milestone_name: 'accessioned')
      Rails.logger.warn("Skipping #{druid} - not yet accessioned")
      return
    end

    unless VersionService.can_open?(druid: cocina_object.externalIdentifier, version: cocina_object.version)
      Rails.logger.warn("Skipping #{druid} - object is already open")
      return
    end
    Rails.logger.info("Releasing embargo for #{druid}")

    updated_cocina_object = VersionService.open(cocina_object:, description: 'embargo released', significance: 'admin')

    updated_cocina_object = release_cocina_object(updated_cocina_object)

    VersionService.close(druid: updated_cocina_object.externalIdentifier, version: updated_cocina_object.version)

    EventFactory.create(druid:, event_type: 'embargo_released', data: {})

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

    UpdateObjectService.update(cocina_object.new({ access: access_props, structural: structural_props }.compact))
  end

  def access_props_for(cocina_object)
    # Copy access > embargo > useAndReproductionStatement, view, download, location, controlledDigitalLending to access >
    # Remove access > embargo
    access_props = cocina_object.access.to_h.except(:view, :download, :location, :controlledDigitalLending, :useAndReproductionStatement)
    access_props.merge!(access_props[:embargo].except(:releaseDate))
    # Remove embargo
    access_props.delete(:embargo)
    access_props
  end

  def structural_props_for(cocina_object, access_props)
    return nil if cocina_object.structural.nil?

    # Apply access to files
    file_access_props = access_props.slice(:view, :download, :location, :controlledDigitalLending)
    file_access_props[:view] = 'dark' if file_access_props[:view] == 'citation-only'

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

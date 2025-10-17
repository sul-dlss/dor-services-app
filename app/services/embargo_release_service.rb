# frozen_string_literal: true

# Finds objects where the embargo release date has passed for embargoed items
# Builds list of candidate objects by querying the database
#
# Should run once a day from cron
class EmbargoReleaseService
  def self.release_all
    # Find objects to process
    embargoed_items_to_release = RepositoryObject.currently_embargoed_and_releaseable

    return Rails.logger.info('No objects to process') if embargoed_items_to_release.none?

    Rails.logger.debug { "Found #{embargoed_items_to_release.size} objects" }

    embargoed_items_to_release.pluck(:external_identifier).each do |druid|
      release(druid:)
    end
  end

  def self.release(druid:)
    new(druid:).release
  end

  # @param [druid] druid
  def initialize(druid:)
    @druid = druid
  end

  def release # rubocop:disable Metrics/AbcSize
    return unless Workflow::StateService.accessioned?(druid:, version:)

    return unless VersionService.can_open?(druid:, version: version)

    Rails.logger.info("Releasing embargo for #{druid}")

    updated_cocina_object = VersionService.open(cocina_object:, description: 'embargo released')

    updated_cocina_object = release_cocina_object(updated_cocina_object)

    VersionService.close(druid:, version: updated_cocina_object.version)

    EventFactory.create(druid:, event_type: 'embargo_released', data: {})

    # Broadcast this action to a topic
    Notifications::EmbargoLifted.publish(model: updated_cocina_object)
  rescue StandardError => e
    Rails.logger.error("!!! Unable to release embargo for: #{druid}\n#{e.inspect}\n#{e.backtrace.join("\n")}")
    Honeybadger.notify "Unable to release embargo for: #{druid}", backtrace: e.backtrace
  end

  private

  attr_reader :druid

  delegate :version, to: :cocina_object

  def release_cocina_object(cocina_object)
    access_props = access_props_for(cocina_object)

    structural_props = structural_props_for(cocina_object, access_props)

    UpdateObjectService.update(cocina_object: cocina_object.new({ access: access_props,
                                                                  structural: structural_props }.compact))
  end

  def access_props_for(cocina_object)
    # Copy access > embargo > useAndReproductionStatement, view, download, location, controlledDigitalLending
    # to access > Remove access > embargo
    access_props = cocina_object.access.to_h.except(:view, :download, :location, :controlledDigitalLending)
    access_props.merge!(access_props[:embargo].except(:releaseDate, :useAndReproductionStatement))
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

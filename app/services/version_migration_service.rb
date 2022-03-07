# frozen_string_literal: true

# Migrates version history from the versionMetadata datastream to the db.
# This service can be removed once migration of the version history is complete for all objects.
class VersionMigrationService
  def self.migrate(fedora_object)
    new(fedora_object).migrate
  end

  def self.find_and_migrate(druid)
    new(Dor.find(druid)).migrate
  end

  def initialize(fedora_object)
    @fedora_object = fedora_object
  end

  def migrate
    return if ObjectVersion.exists?(druid: fedora_object.pid)

    (1..current_version).each do |version|
      ObjectVersion.create(druid: fedora_object.pid,
                           version: version,
                           tag: tag_for(version),
                           description: description_for(version))
    end
  end

  private

  attr_reader :fedora_object

  def version_md
    @version_md ||= fedora_object.versionMetadata
  end

  def current_version
    @current_version ||= version_md.current_version_id.to_i
  rescue Rubydora::FedoraInvalidRequest => e
    new_message = "unable to get current version - #{e.message}"
    raise e.class.exception(new_message)
  end

  def tag_for(version)
    version_md.tag_for_version(version.to_s).presence
  end

  def description_for(version)
    version_md.description_for_version(version.to_s).presence
  end
end

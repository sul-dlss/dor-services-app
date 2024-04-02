# frozen_string_literal: true

# Version history for an object.
# version should correspond with version in cocina model.
class ObjectVersion < ApplicationRecord
  # @param [String] druid
  # @param [String] description text describing version change
  # @return [ObjectVersion] created ObjectVersion
  def self.increment_version(druid:, description:)
    if ObjectVersion.exists?(druid:)
      current_object_version = current_version(druid)
      ObjectVersion.create(druid:, version: current_object_version.version + 1, description:)
    else
      initial_version(druid:)
    end
  end

  # @param [String] druid
  # @return [ObjectVersion] created ObjectVersion
  def self.initial_version(druid:)
    ObjectVersion.create(druid:, version: 1, description: 'Initial Version')
  end

  # Compares the current_version with the passed in known_version (usually SDRs version)
  #   If the known_version is greater than the current version, then all version nodes greater than the known_version are removed,
  #   then the current_version is incremented.  This repairs the case where a previous call to open a new verison
  #   updates the versionMetadata datastream, but versioningWF is not initiated.  Prevents the versions from getting
  #   out of sync with SDR
  #
  # @param [String] druid
  # @param [Integer] known_version object version you wish to sync to, usually SDR's version
  # @param [String] description text describing version change
  # @return [ObjectVersion] created ObjectVersion
  def self.sync_then_increment_version(druid:, known_version:, description:)
    current_version = current_version(druid)&.version || 0

    raise VersionService::VersioningError, "Cannot sync to a version greater than current: #{current_version}, requested #{known_version}" if current_version < known_version

    ObjectVersion.where(druid:).where('version > ?', known_version).destroy_all if current_version > known_version

    increment_version(druid:, description:)
  end

  # @param [String] druid
  # @param [String] description optional text describing version change
  # @return [ObjectVersion] created ObjectVersion
  def self.update_current_version(druid:, description: nil)
    return if description.nil? # no need to update

    current_object_version = current_version(druid)
    return if current_object_version.nil? || current_object_version.version == 1

    current_object_version.description = description
    current_object_version.save!
  end

  # @return [ObjectVersion] current ObjectVersion
  def self.current_version(druid)
    ObjectVersion.where(druid:).order(version: :desc).first
  end

  # @param [String] druid
  # @return [String] xml representation of version metadata
  def self.version_xml(druid)
    object_versions = ObjectVersion.where(druid:).order(:version)

    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.versionMetadata({ objectId: druid }) do
        object_versions.each do |object_version|
          xml.version({ versionId: object_version.version }.compact) do
            xml.description(object_version.description) if object_version.description
          end
        end
      end
    end.to_xml
  end
end

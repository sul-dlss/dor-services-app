# frozen_string_literal: true

# Version history for an object.
# version should correspond with version in cocina model.
class ObjectVersion < ApplicationRecord
  # @param [String] druid
  # @param [Symbol] significance which part of the version tag to increment
  #  :major, :minor, :admin (see VersionTag#increment)
  # @param [String] description optional text describing version change
  # @return [ObjectVersion] created ObjectVersion
  def self.increment_version(druid, significance: nil, description: nil)
    if ObjectVersion.exists?(druid: druid)
      current_object_version = current_version(druid)
      current_tag = VersionTag.parse(current_object_version.tag)

      new_version = current_object_version.version + 1
      new_tag = significance && current_tag ? current_tag.increment(significance).to_s : nil
      new_description = description
    else
      new_version = 1
      new_tag = '1.0.0'
      new_description = 'Initial Version'
    end
    ObjectVersion.create(druid: druid, version: new_version, tag: new_tag, description: new_description)
  end

  # Compares the current_version with the passed in known_version (usually SDRs version)
  #   If the known_version is greater than the current version, then all version nodes greater than the known_version are removed,
  #   then the current_version is incremented.  This repairs the case where a previous call to open a new verison
  #   updates the versionMetadata datastream, but versioningWF is not initiated.  Prevents the versions from getting
  #   out of synch with SDR
  #
  # @param [String] druid
  # @param [Integer] known_version object version you wish to synch to, usually SDR's version
  # @param [Symbol] significance which part of the version tag to increment
  #  :major, :minor, :admin (see VersionTag#increment)
  # @param [String] description optional text describing version change
  # @return [ObjectVersion] created ObjectVersion
  def self.sync_then_increment_version(druid, known_version, significance: nil, description: nil)
    current_version = current_version(druid)&.version || 0

    raise Dor::Exception, "Cannot sync to a version greater than current: #{current_version}, requested #{known_version}" if current_version < known_version

    ObjectVersion.where(druid: druid).where('version > ?', known_version).destroy_all if current_version > known_version

    increment_version(druid, significance: significance, description: description)
  end

  # @param [String] druid
  # @param [Symbol] significance which part of the version tag to increment
  #  :major, :minor, :admin (see VersionTag#increment)
  # @param [String] description optional text describing version change
  # @return [ObjectVersion] created ObjectVersion
  def self.update_current_version(druid, significance: nil, description: nil)
    return if significance.nil? && description.nil?

    current_object_version = current_version(druid)

    return if current_object_version.nil? || current_object_version.version == 1

    current_object_version.description = description if description

    if significance
      # Greatest version with a tag.
      last_object_version = ObjectVersion.where(druid: druid).where.not(tag: nil, version: current_object_version.version).order(version: :desc).first
      last_tag = VersionTag.parse(last_object_version.tag)
      current_object_version.tag = last_tag.increment(significance).to_s
    end

    current_object_version.save!
  end

  # @param [String] druid
  # @return [Boolean] returns true if the current version has a tag and a description, false otherwise
  def self.current_version_closeable?(druid)
    current_object_version = current_version(druid)
    (current_object_version&.tag && current_object_version&.description).present?
  end

  # @return [ObjectVersion] current ObjectVersion
  def self.current_version(druid)
    ObjectVersion.where(druid: druid).order(version: :desc).first
  end
end

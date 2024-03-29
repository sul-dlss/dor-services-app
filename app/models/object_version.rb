# frozen_string_literal: true

# Version history for an object.
# version should correspond with version in cocina model.
class ObjectVersion < ApplicationRecord
  # @param [String] druid
  # @param [Symbol] significance which part of the version tag to increment
  #  :major, :minor, :admin (see VersionTag#increment)
  # @param [String] description text describing version change
  # @return [ObjectVersion] created ObjectVersion
  def self.increment_version(druid:, significance:, description:)
    if ObjectVersion.exists?(druid:)
      current_object_version = current_version(druid)
      current_tag = VersionTag.parse(current_object_version.tag)
      new_tag = significance && current_tag ? current_tag.increment(significance).to_s : nil

      ObjectVersion.create(druid:, version: current_object_version.version + 1, tag: new_tag, description:)
    else
      initial_version(druid:)
    end
  end

  # @param [String] druid
  # @return [ObjectVersion] created ObjectVersion
  def self.initial_version(druid:)
    ObjectVersion.create(druid:, version: 1, tag: '1.0.0', description: 'Initial Version')
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
  # @param [String] description text describing version change
  # @return [ObjectVersion] created ObjectVersion
  def self.sync_then_increment_version(druid:, known_version:, significance:, description:)
    current_version = current_version(druid)&.version || 0

    raise VersionService::VersioningError, "Cannot sync to a version greater than current: #{current_version}, requested #{known_version}" if current_version < known_version

    ObjectVersion.where(druid:).where('version > ?', known_version).destroy_all if current_version > known_version

    increment_version(druid:, significance:, description:)
  end

  # @param [String] druid
  # @param [Symbol] significance (optional) which part of the version tag to increment
  #  :major, :minor, :admin (see VersionTag#increment)
  # @param [String] description optional text describing version change
  # @return [ObjectVersion] created ObjectVersion
  def self.update_current_version(druid:, significance: nil, description: nil)
    return if significance.nil? && description.nil? # no need to update

    current_object_version = current_version(druid)
    return if current_object_version.nil? || current_object_version.version == 1

    current_object_version.description = description if description.present?

    if significance
      # Greatest version with a tag.
      last_object_version = ObjectVersion.where(druid:)
                                         .where.not(tag: nil)
                                         .where.not(version: current_object_version.version)
                                         .order(version: :desc).first
      last_tag = VersionTag.parse(last_object_version.tag)
      current_object_version.tag = last_tag.increment(significance).to_s
    end

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
          xml.version({ versionId: object_version.version, tag: object_version.tag }.compact) do
            xml.description(object_version.description) if object_version.description
          end
        end
      end
    end.to_xml
  end
end

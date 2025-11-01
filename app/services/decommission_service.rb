# frozen_string_literal: true

# Handles the decommissioning of objects
class DecommissionService
  class DecommissionFailed < StandardError; end

  DECOMMISSION_ACCESS = { view: 'dark', download: 'none' }.freeze
  DECOMMISSION_APO = { hasAdminPolicy: Settings.graveyard_admin_policy.druid }.freeze

  attr_reader :druid, :description, :sunetid

  # Decommissions an object
  # @param [String] druid
  # @param [String] description reason for decommissioning
  # @param [String] sunetid user performing the decommission
  # @return [Cocina::Models::DROWithMetadata] updated cocina object
  def self.decommission(druid:, description:, sunetid:)
    new(druid:, description:, sunetid:).decommission
  end

  def initialize(druid:, description:, sunetid:)
    @druid = druid
    @description = description
    @sunetid = sunetid
  end

  def decommission
    repository_object.open_version!(description:)

    updated_cocina_object = decommissioned_cocina_object
    set_decommissioned_tags
    release_workflow

    repository_object.close_version!(description:)

    updated_cocina_object
  end

  private

  def repository_object
    RepositoryObject.find_by!(external_identifier: druid)
  end

  def cocina_object
    repository_object.head_version.to_cocina_with_metadata
  end

  def set_decommissioned_tags
    ReleaseTagService.latest_release_tags(druid:).each do |release_tag|
      next unless release_tag.release

      ReleaseTagService.create(tag: decommission_tag(release_tag),
                               cocina_object:,
                               create_only: true)
    end

    AdministrativeTags.create(identifier: druid,
                              tags: ["Decommissioned : #{description}"])
  end

  def release_workflow
    Workflow::Service.create(workflow_name: 'releaseWF',
                             druid:,
                             version: repository_object.head_version_version)
  end

  # Updates the cocina object, removing its structural contains and setting appropriate
  # access (dark) and administrative (graveyard APO) for decommissioning.
  # @return [Cocina::Models::DROWithMetadata] cocina object updated for decommission
  def decommissioned_cocina_object
    structural = Cocina::Models::DROStructural.new(cocina_object.structural&.to_h&.except(:contains))

    UpdateObjectService.update(cocina_object: cocina_object.new(access: DECOMMISSION_ACCESS,
                                                                administrative: DECOMMISSION_APO,
                                                                structural:),
                               description: "Decommissioned: #{description}",
                               who: sunetid)
  end

  # Builds a release tag for decommissioning based on an existing release tag
  # @param [Cocina::Models::ReleaseTag] release_tag
  # @return [Dor::ReleaseTag] decommission release tag
  def decommission_tag(release_tag)
    Dor::ReleaseTag.new(
      to: release_tag.to,
      who: release_tag.who,
      what: release_tag.what,
      release: false,
      date: DateTime.now.utc.iso8601
    )
  end
end

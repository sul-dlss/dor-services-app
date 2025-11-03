# frozen_string_literal: true

# Handles the decommissioning of objects
class DecommissionService
  def self.decommission(...)
    new(...).decommission
  end

  # Decommissions an object
  # @param [String] druid
  # @param [String] description description for decommissioning (usually a TICKET reference)
  # @param [String] sunetid user performing the decommission
  # @return [Cocina::Models::DROWithMetadata] updated cocina object
  def initialize(druid:, description:, sunetid:)
    @druid = druid
    @description = description
    @sunetid = sunetid
  end

  attr_reader :druid, :description, :sunetid

  def decommission
    cocina_object = VersionService.open(cocina_object: CocinaObjectStore.find(druid),
                                        description: "Decommissioned: #{description}",
                                        assume_accessioned: false,
                                        opening_user_name: sunetid)

    updated_cocina_object = decommission_cocina_object(cocina_object:)

    set_decommission_release_tags(cocina_object: updated_cocina_object)
    set_decommission_admin_tags(cocina_object: updated_cocina_object)
    start_release_workflow(cocina_object: updated_cocina_object)

    VersionService.close(druid:,
                         version: updated_cocina_object.version,
                         user_name: sunetid)

    updated_cocina_object
  end

  private

  def decommission_cocina_object(cocina_object:)
    structural = Cocina::Models::DROStructural.new(cocina_object.structural&.to_h&.except(:contains))

    UpdateObjectService.update(cocina_object: cocina_object.new(access: {
                                                                  view: 'dark',
                                                                  download: 'none'
                                                                },
                                                                administrative: {
                                                                  hasAdminPolicy: Settings.graveyard_admin_policy.druid
                                                                },
                                                                structural:),
                               description: "Decommissioned: #{description}",
                               who: sunetid)
  end

  def set_decommission_release_tags(cocina_object:)
    ReleaseTagService.latest_release_tags(druid:).each do |release_tag|
      next unless release_tag.release

      ReleaseTagService.create(tag: decommission_tag(release_tag),
                               cocina_object:,
                               create_only: true)
    end
  end

  def set_decommission_admin_tags(cocina_object:)
    AdministrativeTags.create(identifier: cocina_object.externalIdentifier,
                              tags: ["Decommissioned : #{description}"])
  end

  def start_release_workflow(cocina_object:)
    Workflow::Service.create(workflow_name: 'releaseWF',
                             druid: cocina_object.externalIdentifier,
                             version: cocina_object.version)
  end

  def decommission_tag(release_tag)
    Dor::ReleaseTag.new(
      to: release_tag.to,
      who: sunetid,
      what: release_tag.what,
      release: false,
      date: DateTime.now.utc.iso8601
    )
  end
end

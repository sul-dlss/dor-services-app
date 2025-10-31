# frozen_string_literal: true

# Handles the decommissioning of objects
class DecommissionService
  class DecommissionFailed < StandardError; end

  DECOMMISSION_ACCESS = { view: 'dark', download: 'none' }.freeze
  DECOMMISSION_APO = { hasAdminPolicy: Settings.graveyard_admin_policy.druid }.freeze

  attr_reader :cocina_object, :reason, :sunetid

  def self.decommission(cocina_object:, reason:, sunetid:)
    new(cocina_object:, reason:, sunetid:).decommission
  end

  def initialize(cocina_object:, reason:, sunetid:)
    @cocina_object = cocina_object
    @reason = reason
    @sunetid = sunetid
  end

  def decommission
    VersionService.open(cocina_object:,
                        description: "Decommissioned: #{reason}",
                        assume_accessioned: true,
                        opening_user_name: sunetid)

    updated_cocina_object = UpdateObjectService.update(cocina_object: decommissioned_cocina_object,
                                                       description: "Decommissioned: #{reason}",
                                                       who: sunetid)

    set_decommissioned_tags
    release_workflow

    VersionService.close(druid:,
                         version: updated_cocina_object.version,
                         description: "Decommissioned: #{reason}",
                         user_name: sunetid)

    updated_cocina_object
  end

  private

  def druid
    cocina_object.externalIdentifier
  end

  def set_decommissioned_tags
    ReleaseTagService.latest_release_tags(druid:).each do |release_tag|
      next unless release_tag.release

      ReleaseTagService.create(tag: decommission_tag(release_tag),
                               cocina_object:,
                               create_only: true)
    end

    AdministrativeTags.create(identifier: cocina_object.externalIdentifier,
                              tags: ["Decommissioned : #{reason}"])
  end

  def release_workflow
    Workflow::Service.create(workflow_name: 'releaseWF',
                             druid: cocina_object.externalIdentifier,
                             version: cocina_object.version)
  end

  def decommissioned_cocina_object
    structural = Cocina::Models::DROStructural.new(cocina_object.structural&.to_h&.except(:contains))

    cocina_object.new(access: DECOMMISSION_ACCESS,
                      administrative: DECOMMISSION_APO,
                      structural:)
  end

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

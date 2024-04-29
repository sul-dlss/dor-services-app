# frozen_string_literal: true

# Migrate Dro, Collection, AdminPolicy, and ObjectVersion AR models to the
# RepositoryObject and RepositoryObjectVersion models.
class RepositoryObjectMigrator
  def self.migrate(...)
    new(...).migrate
  end

  def initialize(external_identifier:)
    @external_identifier = external_identifier
  end

  def migrate
    RepositoryObject.transaction do
      # There is already logic below that will build up all the versions and relationships.
      new_object.update!(opened_version: nil, head_version: nil)
      1.upto(current_version_number).each do |version_number|
        old_object_version = object_version_by(version_number:)
        raise "No legacy ObjectVersion model found for #{external_identifier} / #{version_number}" unless old_object_version

        new_object_version = migrate_old_object_version(old_object_version, version_number:, current: version_number == current_version_number)
        if open_version?(version_number:)
          new_object.update!(opened_version: new_object_version, head_version: new_object_version)
        else
          new_object.update!(last_closed_version: new_object_version, head_version: new_object_version)
        end
      end
    end
    # Patch in the old object's updated_at now that we're done making changes
    new_object.update!(updated_at: old_object.updated_at)
    new_object
  end

  private

  attr_reader :external_identifier

  def migrate_old_object_version(old_object_version, version_number:, current:)
    new_object.versions.find_or_initialize_by(version: version_number).tap do |new_object_version|
      object_version_attributes = {
        created_at: old_object_version.created_at,
        updated_at: old_object_version.updated_at,
        version_description: old_object_version.description,
        closed_at: closed_at(version_number:)
      }.tap do |attrs|
        # NOTE: Only migrate cocina attrs for the current version
        next unless current

        attrs[:cocina_version] = old_object.cocina_version
        attrs[:content_type] = content_type
        attrs[:label] = old_object.label
        attrs[:access] = access
        attrs[:administrative] = old_object.administrative
        attrs[:description] = description
        attrs[:identification] = identification
        attrs[:structural] = structural
        attrs[:geographic] = geographic
      end
      new_object_version.update!(**object_version_attributes)
    end
  end

  def old_object
    @old_object ||= CocinaObjectStore.ar_find(external_identifier)
  end

  def new_object
    @new_object ||= RepositoryObject.create!(
      external_identifier:,
      source_id:,
      object_type: old_object.class.to_s.underscore,
      created_at: old_object.created_at,
      lock: old_object.lock
    )
  end

  def current_version_number
    old_object.version
  end

  def object_versions
    @object_versions ||= ObjectVersion.where(druid: external_identifier).order(version: :asc)
  end

  def object_version_by(version_number:)
    object_versions.find_by(version: version_number)
  end

  def open_version?(version_number:)
    VersionService.new(druid: external_identifier, version: version_number).open?
  end

  def closed_at(version_number:)
    status = workflow_status(version_number:)
    return unless status.display_simplified == 'Accessioned'

    Time.parse(
      status.send(:status_time)
    ).utc
  end

  def workflow_status(version_number:)
    WorkflowClientFactory.build.status(druid: external_identifier, version: version_number)
  end

  def source_id
    return unless old_object.respond_to?(:identification)

    old_object.identification['sourceId']
  end

  def content_type
    return old_object.collection_type if old_object.respond_to?(:collection_type)

    return old_object.content_type if old_object.respond_to?(:content_type)

    Cocina::Models::ObjectType.admin_policy
  end

  def access
    return unless old_object.respond_to?(:access)

    old_object.access
  end

  def description
    return unless old_object.respond_to?(:description)

    old_object.description
  end

  def identification
    return unless old_object.respond_to?(:identification)

    old_object.identification
  end

  def structural
    return unless old_object.respond_to?(:structural)

    old_object.structural
  end

  def geographic
    return unless old_object.respond_to?(:geographic)

    old_object.geographic
  end
end

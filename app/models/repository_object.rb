# frozen_string_literal: true

# Models a repository object (item/DRO, collection, or admin policy)

# In general, the direct use of RepositoryObjects should be limited; most components should be using Cocina Models
# and using the services below:
# For finding / querying, see CocinaObjectStore.
# For versioning operations, see VersionService.
# For persistence, see CreateObjectService and UpdateObjectService.
# For destroying, see DeleteService.
class RepositoryObject < ApplicationRecord
  self.locking_column = 'lock'

  class VersionAlreadyOpened < StandardError; end
  class VersionNotOpened < StandardError; end
  class VersionNotDiscardable < StandardError; end

  has_many :versions, lambda {
    order(version: :asc)
  }, class_name: 'RepositoryObjectVersion', dependent: :destroy, inverse_of: 'repository_object', autosave: true
  has_many :user_versions, through: :versions

  belongs_to :head_version, class_name: 'RepositoryObjectVersion', optional: true
  belongs_to :last_closed_version, class_name: 'RepositoryObjectVersion', optional: true
  belongs_to :opened_version, class_name: 'RepositoryObjectVersion', optional: true

  enum :object_type, %i[dro admin_policy collection].index_with(&:to_s)

  validates :external_identifier, :object_type, presence: true
  validates :source_id, presence: true, if: -> { dro? }
  validate :last_closed_and_open_cannot_be_same_version
  validate :head_must_be_either_last_closed_or_opened

  after_create :open_first_version
  before_destroy :unset_version_relationships, prepend: true

  scope :dros, -> { where(object_type: 'dro') }
  scope :collections, -> { where(object_type: 'collection') }
  scope :admin_policies, -> { where(object_type: 'admin_policy') }
  scope :closed, -> { where('last_closed_version_id = head_version_id') }

  delegate :to_cocina, :to_cocina_with_metadata, to: :head_version

  def head_user_version
    @head_user_version ||= user_versions.maximum(:version)
  end

  # NOTE: This block uses metaprogramming to create the equivalent of scopes that query the RepositoryObjectVersion
  # table using only rows that are a `current` in the RepositoryObject table
  #
  # So it's a more easily extensible version of:
  #
  # scope :currently_in_virtual_objects, ->(member_druid) { joins(:head_version).merge(RepositoryObjectVersion
  # .in_virtual_objects(member_druid)) }
  # scope :currently_members_of_collection, ->(collection_druid) { joins(:head_version).merge(RepositoryObjectVersion
  # .members_of_collection(collection_druid)) }
  class << self
    def method_missing(method_name, ...)
      if method_name.to_s =~ /#{current_scope_prefix}(.*)/
        joins(:head_version).merge(
          RepositoryObjectVersion.public_send(Regexp.last_match(1).to_sym, ...)
        )
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.start_with?(current_scope_prefix) || super
    end

    # @param [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object a Cocina
    #   model instance, either a DRO, collection, or APO.
    def create_from(cocina_object:)
      args = {
        external_identifier: cocina_object.externalIdentifier,
        object_type: cocina_object.class.name.demodulize.underscore
      }
      args[:source_id] = cocina_object.identification.sourceId if cocina_object.respond_to?(:identification)
      create!(**args).tap do |repo_obj|
        repo_obj.update_opened_version_from(cocina_object:)
      end
    end

    private

    def current_scope_prefix
      'currently_'
    end
  end

  # @param [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object a Cocina
  #   model instance, either a DRO, collection, or APO.
  def update_opened_version_from(cocina_object:)
    opened_version.update!(**RepositoryObjectVersion.to_model_hash(cocina_object))
    reload # Syncs up head_version and opened_version
  end

  # @param [String] description for the version
  # @param [RepositoryObjectVersion,nil] from_version existing version to base the new version on. If nil, then uses
  # last_closed_version.
  def open_version!(description:, from_version: nil)
    raise VersionAlreadyOpened, "Cannot open new version because one is already open: #{head_version.version}" if open?

    RepositoryObject.transaction do
      new_version = (from_version || last_closed_version).dup
      new_version.update!(version: last_closed_version.version + 1, version_description: description, closed_at: nil)
      update!(opened_version: new_version, head_version: new_version)
    end
  end

  def close_version!(description: nil)
    raise VersionNotOpened, "Cannot close version because head version is closed: #{head_version.version}" if closed?

    RepositoryObject.transaction do
      opened_version.update!(closed_at: Time.current,
                             version_description: description || opened_version.version_description)
      update!(opened_version: nil, last_closed_version: opened_version, head_version: opened_version)
    end
  end

  def check_discard_open_version!
    raise VersionNotDiscardable, 'Cannot discard version because head version is closed' if closed?
    raise VersionNotDiscardable, 'Cannot discard version because this is the first version' if last_closed_version.nil?

    return if last_closed_version.has_cocina?

    raise VersionNotDiscardable,
          'Cannot discard version because last closed version does not have cocina'
  end

  def can_discard_open_version?
    check_discard_open_version!
    true
  rescue VersionNotDiscardable
    false
  end

  def discard_open_version!
    check_discard_open_version!

    RepositoryObject.transaction do
      discard_version = opened_version
      update!(opened_version: nil, head_version: last_closed_version)
      discard_version.destroy!
    end
  end

  # Reopening should only be performed as part of remediation or cleanup.
  def reopen!
    raise VersionAlreadyOpened, 'Cannot reopen version because already open' if open?

    RepositoryObject.transaction do
      head_version.update!(closed_at: nil)
      # Yes, this may set last_closed_version to nil. That's fine.
      update!(opened_version: head_version, last_closed_version: versions.find_by(version: head_version.version - 1))
    end
  end

  def open?
    head_version == opened_version
  end

  def closed?
    head_version == last_closed_version
  end

  # When a collection object is published, publish the collection members that:
  # * have a last closed version (meaning they are not Registered - they've been accessioned); and
  # * there's cocina for that last closed version (meaning they've been closed at least once since we moved to
  # the new version model)
  def publishable?
    last_closed_version.present? && last_closed_version.has_cocina?
  end

  # @return [String] xml representation of version metadata
  def version_xml
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.versionMetadata({ objectId: external_identifier }) do
        versions.each do |object_version|
          xml.version({ versionId: object_version.version }.compact) do
            xml.description(object_version.version_description)
          end
        end
      end
    end.to_xml
  end

  # Lock used for API. It is part of a cocina object with metadata.
  # The external lock is checked in the UpdateObjectService.
  def external_lock
    # This should be opaque, but this makes troubeshooting easier.
    # The external_identifier is included so that there is enough entropy such
    # that the lock can't be used for an object it doesn't belong to as the
    # lock column is just an integer sequence.
    [external_identifier, lock.to_s, head_version.lock.to_s].join('=')
  end

  def check_lock!(cocina_object)
    return if cocina_object.respond_to?(:lock) && external_lock == cocina_object.lock

    raise CocinaObjectStore::StaleLockError, "Expected lock of #{external_lock} but received #{cocina_object.lock}."
  end

  private

  def open_first_version
    RepositoryObject.transaction do
      first_version = versions.create!(version: 1, version_description: 'Initial version')
      update!(opened_version: first_version, head_version: first_version)
    end
  end

  def unset_version_relationships
    update(last_closed_version: nil, head_version: nil, opened_version: nil)
  end

  def last_closed_and_open_cannot_be_same_version
    return if (last_closed_version.nil? && opened_version.nil?) || last_closed_version != opened_version

    errors.add(:last_closed_version, 'cannot be the same version as the open version')
  end

  def head_must_be_either_last_closed_or_opened
    return if head_version.nil? || head_version == last_closed_version || head_version == opened_version

    errors.add(:head_version, 'must point at either the last closed version or the opened version')
  end
end

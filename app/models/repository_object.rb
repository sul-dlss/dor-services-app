# frozen_string_literal: true

# Models a repository object (item/DRO, collection, or admin policy)

# In general, the direct use of RepositoryObjects should be limited; most components should be using Cocina Models and using the services below:
# For finding / querying, see CocinaObjectStore.
# For versioning operations, see VersionService.
# For persistence, see CreateObjectService and UpdateObjectService.
# For destroying, see DeleteService.
class RepositoryObject < ApplicationRecord
  class VersionAlreadyOpened < StandardError; end
  class VersionNotOpened < StandardError; end

  has_many :versions, -> { order(version: :asc) }, class_name: 'RepositoryObjectVersion', dependent: :destroy, inverse_of: 'repository_object'
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

  # NOTE: This block uses metaprogramming to create the equivalent of scopes that query the RepositoryObjectVersion table using only rows that are a `current` in the RepositoryObject table
  #
  # So it's a more easily extensible version of:
  #
  # scope :currently_in_virtual_objects, ->(member_druid) { joins(:head_version).merge(RepositoryObjectVersion.in_virtual_objects(member_druid)) }
  # scope :currently_members_of_collection, ->(collection_druid) { joins(:head_version).merge(RepositoryObjectVersion.members_of_collection(collection_druid)) }
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
      create!(**args).update_opened_version_from(cocina_object:)
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
  end

  def open_version!(description:)
    raise VersionAlreadyOpened, "Cannot open new version because one is already open: #{head_version.version}" if open?

    RepositoryObject.transaction do
      new_version = last_closed_version.dup
      new_version.update!(version: new_version.version + 1, version_description: description)
      update!(opened_version: new_version, head_version: new_version)
    end
  end

  def close_version!(description: nil)
    raise VersionNotOpened, "Cannot close version because head version is closed: #{head_version.version}" if closed?

    RepositoryObject.transaction do
      opened_version.update!(closed_at: Time.current, version_description: description || opened_version.version_description)
      update!(opened_version: nil, last_closed_version: opened_version, head_version: opened_version)
    end
  end

  def open?
    head_version == opened_version
  end

  def closed?
    head_version == last_closed_version
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

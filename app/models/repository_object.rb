# frozen_string_literal: true

# Models a repository object (item/DRO, collection, or admin policy)
class RepositoryObject < ApplicationRecord
  class VersionAlreadyOpened < StandardError; end
  class VersionNotOpened < StandardError; end

  has_many :versions,  class_name: 'RepositoryObjectVersion', dependent: :destroy, inverse_of: 'repository_object'

  belongs_to :current, class_name: 'RepositoryObjectVersion', optional: true
  belongs_to :head, class_name: 'RepositoryObjectVersion', optional: true
  belongs_to :open, class_name: 'RepositoryObjectVersion', optional: true

  enum :object_type, %i[dro admin_policy collection].index_with(&:to_s)

  validates :external_identifier, :object_type, presence: true
  validates :source_id, presence: true, if: -> { dro? }
  validate :head_and_open_cannot_be_same_version
  validate :current_must_be_either_head_or_open

  after_create_commit :open_first_version
  before_destroy :unset_version_relationships, prepend: true

  # NOTE: This block uses metaprogramming to create the equivalent of scopes that query the RepositoryObjectVersion table using only rows that are a `current` in the RepositoryObject table
  #
  # So it's a more easily extensible version of:
  #
  # scope :currently_in_virtual_objects, ->(member_druid) { joins(:current).merge(RepositoryObjectVersion.in_virtual_objects(member_druid)) }
  # scope :currently_members_of_collection, ->(collection_druid) { joins(:current).merge(RepositoryObjectVersion.members_of_collection(collection_druid)) }
  class << self
    def method_missing(method_name, ...)
      if method_name.to_s =~ /#{current_scope_prefix}(.*)/
        joins(:current).merge(
          RepositoryObjectVersion.public_send(Regexp.last_match(1).to_sym, ...)
        )
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.start_with?(current_scope_prefix) || super
    end

    private

    def current_scope_prefix
      'currently_'
    end
  end

  def open_version!
    raise VersionAlreadyOpened, "Cannot open new version because one is already open: #{current.version}" if open?

    RepositoryObject.transaction do
      version_to_open = head.dup.tap { |object_version| object_version.version += 1 }
      update!(open: version_to_open, current: version_to_open)
    end
  end

  def close_version!
    raise VersionNotOpened, "Cannot close version because current version is closed: #{current.version}" if closed?

    RepositoryObject.transaction do
      version_to_close = self.open.tap { |object_version| object_version.closed_at = Time.current }
      update!(open: nil, head: version_to_close, current: version_to_close)
    end
  end

  def open?
    current == open
  end

  def closed?
    current == head
  end

  private

  def open_first_version
    RepositoryObject.transaction do
      first_version = versions.create!(version: 1, version_description: 'Initial version')
      update!(open: first_version, current: first_version)
    end
  end

  def unset_version_relationships
    update(head: nil, current: nil, open: nil)
  end

  def head_and_open_cannot_be_same_version
    return if (head.nil? && open.nil?) || head != open

    errors.add(:head, 'cannot be the same version as the open version')
  end

  def current_must_be_either_head_or_open
    return if current.nil? || current == head || current == open

    errors.add(:current, 'must point at either the head version or the open version')
  end
end

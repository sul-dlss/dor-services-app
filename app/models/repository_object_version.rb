# frozen_string_literal: true

# Models a repository object as it looked at a particular version.
class RepositoryObjectVersion < ApplicationRecord
  belongs_to :repository_object
  has_many :user_versions, dependent: :destroy

  has_one :head_version_of, class_name: 'RepositoryObject', inverse_of: :head_version, dependent: nil
  scope :in_virtual_objects, ->(member_druid) { where("structural #> '{hasMemberOrders,0}' -> 'members' ? :druid", druid: member_druid) }
  scope :members_of_collection, ->(collection_druid) { where("structural -> 'isMemberOf' ? :druid", druid: collection_druid) }

  validates :version, :version_description, presence: true
  after_save :update_object_source_id

  delegate :external_identifier, to: :repository_object

  # @param [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object a Cocina
  #   model instance, either a DRO, collection, or APO.
  # @return [Hash] Hash representation of a Cocina object suitable to be passed to an object type-specific AR update
  def self.to_model_hash(cocina_object)
    cocina_object
      .to_h
      .except(:externalIdentifier, :version)
      .tap do |object_hash|
      object_hash[:cocina_version] = object_hash.delete(:cocinaVersion)
      object_hash[:content_type] = object_hash.delete(:type)
      case cocina_object
      when Cocina::Models::DRO
        object_hash[:geographic] ||= nil
      when Cocina::Models::AdminPolicy
        object_hash[:description] ||= nil
      end
    end
  end

  def external_lock
    # This should be opaque, but this makes troubeshooting easier.
    # The external_identifier is included so that there is enough entropy such
    # that the lock can't be used for an object it doesn't belong to as the
    # lock column is just an integer sequence.
    [repository_object.external_identifier, repository_object.lock.to_s].join('=')
  end

  def to_cocina_with_metadata
    Cocina::Models.with_metadata(to_cocina, external_lock, created: created_at.utc, modified: updated_at.utc)
  end

  def to_cocina
    Cocina::Models.build(to_h)
  end

  # @return [Hash] RepositoryObjectVersion instance as a hash
  def to_h
    {
      cocinaVersion: cocina_version,
      type: content_type,
      externalIdentifier: repository_object.external_identifier,
      label:,
      version:,
      access:,
      administrative:,
      description:,
      identification:,
      structural:,
      geographic:
    }.compact
  end

  def closed?
    closed_at.present?
  end

  def open?
    !closed?
  end

  private

  def update_object_source_id
    source_id = identification&.fetch('sourceId', nil)
    # only update object if opened. opened_version will also be the object's head_version
    return unless repository_object.opened_version == self && source_id
    return if repository_object.source_id == source_id

    repository_object.update!(source_id:)
  end
end

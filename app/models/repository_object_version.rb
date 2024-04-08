# frozen_string_literal: true

# Models a repository object as it looked at a particular version.
class RepositoryObjectVersion < ApplicationRecord
  belongs_to :repository_object

  scope :in_virtual_objects, ->(member_druid) { where("structural #> '{hasMemberOrders,0}' -> 'members' ? :druid", druid: member_druid) }
  scope :members_of_collection, ->(collection_druid) { where("structural -> 'isMemberOf' ? :druid", druid: collection_druid) }

  validates :version, :version_description, presence: true
  after_save :update_object_source_id

  # @param [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy] cocina_object a Cocina
  #   model instance, either a DRO, collection, or APO.
  # @return [Hash] Hash representation of a Cocina object suitable to be passed to an object type-specific AR update
  def self.to_model_hash(cocina_object)
    cocina_object
      .to_h
      .except(:externalIdentifier, :version)
      .tap do |object_hash|
      object_hash[:cocina_version] = object_hash.delete(:cocinaVersion)
      if cocina_object.dro?
        object_hash[:content_type] = object_hash.delete(:type)
        object_hash[:geographic] ||= nil
      elsif cocina_object.collection?
        object_hash[:content_type] = object_hash.delete(:type)
      elsif cocina_object.admin_policy?
        object_hash.delete(:type)
        object_hash[:description] ||= nil
      end
    end
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

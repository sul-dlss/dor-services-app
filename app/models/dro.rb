# frozen_string_literal: true

# Model for a Digital Repository Object.
class Dro < RepositoryRecord
  validates :content_type, :access, :administrative, :description,
            :identification, :structural, presence: true

  # Note that this query is slow. Creating a timestamp index on the releaseDate field is not supported by PG.
  scope :embargoed_and_releaseable, -> { where("(access -> 'embargo' ->> 'releaseDate')::timestamp <= ?", Time.zone.now) }
  scope :in_virtual_objects, ->(member_druid) { where("structural #> '{hasMemberOrders,0}' -> 'members' ? :druid", druid: member_druid) }
  scope :members_of_collection, ->(collection_druid) { where("structural -> 'isMemberOf' ? :druid", druid: collection_druid) }

  def self.find_by_source_id(source_id)
    find_by("identification->>'sourceId' = ?", source_id)
  end

  # @return [Cocina::Models::DRO] Cocina Digital Repository Object
  def to_cocina
    Cocina::Models::DRO.new(to_h)
  end

  # @return [Hash] DRO/item instance as a hash
  def to_h
    {
      cocinaVersion: cocina_version,
      type: content_type,
      externalIdentifier: external_identifier,
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

  # @param [Cocina::Models::DRO] Cocina Digital Repository Object
  # @return [Dro] ActiveRecord Digital Repository Object
  def self.from_cocina(cocina_dro)
    new(to_model_hash(cocina_dro))
  end

  # @param [Cocina::Models::DRO] Cocina Digital Repository Object
  # @return [Hash] Hash representation of ActiveRecord DRO
  def self.to_model_hash(cocina_dro)
    dro_hash = cocina_dro.to_h
    dro_hash[:external_identifier] = dro_hash.delete(:externalIdentifier)
    dro_hash[:cocina_version] = dro_hash.delete(:cocinaVersion)
    dro_hash[:content_type] = dro_hash.delete(:type)
    dro_hash[:geographic] ||= nil
    dro_hash
  end

  # @param [Cocina::Models::DRO] Cocina Digital Repository Object
  def self.upsert_cocina(cocina_dro)
    # Upsert will have to wait until we upgrade to Rails 6.
    # Dro.upsert(to_model_hash(cocina_dro), unique_by: :druid)
    dro = Dro.find_or_initialize_by(external_identifier: cocina_dro.externalIdentifier)
    dro.update(to_model_hash(cocina_dro).except(:external_identifier))
    dro.save!
    dro
  end
end

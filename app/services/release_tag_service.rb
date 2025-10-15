# frozen_string_literal: true

# Shows and creates release tags. This replaces parts of https://github.com/sul-dlss/dor-services/blob/main/lib/dor/models/concerns/releaseable.rb
class ReleaseTagService
  # Retrieve the release tags for an item
  def self.tags(druid:)
    ReleaseTag.where(druid:).map(&:to_cocina)
  end

  # Creates ReleaseTag model objects.
  # @param [Dor::ReleaseTag] tag
  # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina_object
  def self.create(tag:, cocina_object:)
    ReleaseTag.from_cocina(druid: cocina_object.externalIdentifier, tag:).save!
    Indexer.reindex(cocina_object: cocina_object)
  end
end

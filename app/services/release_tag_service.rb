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
  # @param [Boolean] create_only or reindex and releaseWF workflow after creating the tag, defaults to false
  def self.create(tag:, cocina_object:, create_only: false)
    ReleaseTag.from_cocina(druid: cocina_object.externalIdentifier, tag:).save!
    return if create_only

    Indexer.reindex(cocina_object: cocina_object)
    Workflow::Service.create(workflow_name: 'releaseWF', druid: cocina_object.externalIdentifier,
                             version: cocina_object.version)
  end

  # Retrieve the latest release tags for each release target for an item
  # @param [String] druid
  # @return [Array<Cocina::Models::ReleaseTag>]
  def self.latest_for(druid:)
    tags(druid:).pluck(:to).uniq.map do |to|
      tags(druid:).select { |tag| tag.to == to }.max_by(&:date)
    end
  end
end

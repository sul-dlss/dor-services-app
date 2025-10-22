# frozen_string_literal: true

# Shows release tags for public metadata. This replaces parts of https://github.com/sul-dlss/dor-services/blob/main/lib/dor/models/concerns/releaseable.rb
class PublicMetadataReleaseTagService
  # Retrieve the release tags for an item and all the collections that it is a part of
  #
  # Determine projects in which an item is released
  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection] the object to list release tags for
  # @return [Array<Dor::ReleaseTag>]
  def self.for_public_metadata(...)
    new(...).for_public_metadata
  end

  def self.released_to_searchworks?(cocina_object:)
    return false if Cocina::Support.dark?(cocina_object)

    new(cocina_object:).for_public_metadata
                       .find { |tag| tag.to.casecmp?('Searchworks') }&.release || false
  end

  def initialize(cocina_object:)
    @cocina_object = cocina_object
  end

  # Determine projects in which an item is released
  # @return [Array<Dor::ReleaseTag>]
  def for_public_metadata
    # For each release target, item tags trump collection tags
    grouped_latest_tags(collection_tags).merge(grouped_latest_tags(item_tags)).values
  end

  private

  attr_reader :cocina_object

  def collection_tags
    tags = collection_druids.flat_map do |collection_druid|
      ReleaseTagService.tags(druid: collection_druid)
    end
    tags.select { |tag| tag.what == 'collection' }
  end

  def collection_druids
    return [] unless cocina_object.dro?

    cocina_object.structural.isMemberOf
  end

  def item_tags
    ReleaseTagService.tags(druid: cocina_object.externalIdentifier)
  end

  def grouped_latest_tags(release_tags)
    # Group by release target
    grouped_tags = release_tags.group_by(&:to)
    # For each release target, select the most recent release tag
    grouped_tags.transform_values { |tags| tags.max_by(&:date) }
  end
end

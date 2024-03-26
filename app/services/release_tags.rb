# frozen_string_literal: true

# Shows and creates release tags. This replaces parts of https://github.com/sul-dlss/dor-services/blob/main/lib/dor/models/concerns/releaseable.rb
class ReleaseTags
  # Retrieve the release tags for an item and all the collections that it is a part of
  #
  # Determine projects in which an item is released
  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection] the object to list release tags for
  # @return [Array<Cocina::Models::ReleaseTag>]
  def self.for_public_metadata(cocina_object:)
    new(cocina_object).for_public_metadata
  end

  # Retrieve the release tags for an item
  def self.item_tags(cocina_object:)
    new(cocina_object).item_tags
  end

  def self.released_to_searchworks?(cocina_object:)
    new(cocina_object).for_public_metadata
                      .find { |tag| tag.to.casecmp?('Searchworks') }&.release || false
  end

  # Creates ReleaseTag model objects if and only if there are existing ReleaseTag model objects for the item.
  # For now it continues to add release tags to the Cocina
  # The effect of this will be that ReleaseTag model objects will only be created for items that have been migrated.
  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection] the object to add to
  # @param [Cocina::Models::ReleaseTag] tag
  def self.create(cocina_object:, tag:)
    druid = cocina_object.externalIdentifier
    ReleaseTag.from_cocina(druid:, tag:).save! if ReleaseTag.exists?(druid:)
    updated_object = cocina_object.new(
      administrative: cocina_object.administrative.new(
        releaseTags: Array(cocina_object.administrative.releaseTags) + [tag]
      )
    )
    CocinaObjectStore.store(updated_object, skip_lock: true)
  end

  def initialize(cocina_object)
    @cocina_object = cocina_object
  end

  attr_reader :cocina_object

  # Determine projects in which an item is released
  # @return [Hash{String => Boolean}] all namespaces, keys are Project name Strings, values are Boolean
  def for_public_metadata
    all_tags_by_project = (item_tags + collection_tags).group_by(&:to)
    all_tags_by_project.values.map do |project_tags|
      project_tags.max_by(&:date)
    end
  end

  def item_tags
    release_tags = ReleaseTag.where(druid: cocina_object.externalIdentifier).to_a
    # If this object's release tags haven't been migrated to ReleaseTag model objects, get from cocina.
    return cocina_object.administrative.releaseTags if release_tags.empty?

    release_tags.map(&:to_cocina)
  end

  private

  def collection_tags
    collections.flat_map { |collection| collection.administrative.releaseTags }.select { |tag| tag.what == 'collection' }
  end

  def collections
    return [] unless cocina_object.dro?

    cocina_object.structural.isMemberOf.map { |druid| CocinaObjectStore.find(druid) }
  end
end

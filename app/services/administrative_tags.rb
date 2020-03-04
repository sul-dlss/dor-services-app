# frozen_string_literal: true

# Shows and creates administrative tags. This wraps https://github.com/sul-dlss/dor-services/blob/master/lib/dor/services/tag_service.rb
class AdministrativeTags
  # Retrieve the administrative tags for an item
  #
  # @param item [Dor::Item] the item to list administrative tags for
  # @return [Array<String>] an array of tags (strings), possibly empty
  def self.for(item:)
    new(item: item).for
  end

  # Add one or more administrative tags for an item
  #
  # @param item [Dor::Item]  the item to create administrative tag(s) for
  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @return [Array<AdministrativeTag>]
  def self.create(item:, tags:)
    new(item: item).create(tags: tags)
  end

  # Update an administrative tag for an item
  #
  # @param item [Dor::Item]  the item to update an administrative tag for
  # @param current [String] the current administrative tag
  # @param new [String] the replacement administrative tag
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def self.update(item:, current:, new:)
    new(item: item).update(current: current, new: new)
  end

  # Destroy an administrative tag for an item
  #
  # @param item [Dor::Item]  the item to delete an administrative tag for
  # @param tag [String] the administrative tag to delete
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def self.destroy(item:, tag:)
    new(item: item).destroy(tag: tag)
  end

  # @param item [Dor::Item] the item to list administrative tags for
  def initialize(item:)
    @item = item
  end

  # @return [Array<String>] an array of tags (strings), possibly empty
  def for
    populate_legacy_tags_if_empty!

    AdministrativeTag.where(druid: item.pid).pluck(:tag)
  end

  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @return [Array<AdministrativeTag>]
  def create(tags:)
    populate_legacy_tags_if_empty!

    tags.map { |tag| AdministrativeTag.create(druid: item.pid, tag: tag) }
  end

  # Update an administrative tag for an item
  #
  # @param current [String] the current administrative tag
  # @param new [String] the replacement administrative tag
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def update(current:, new:)
    populate_legacy_tags_if_empty!

    AdministrativeTag.find_by!(druid: item.pid, tag: current).update(tag: new)
  end

  # Destroy an administrative tag for an item
  #
  # @param item [Dor::Item]  the item to delete an administrative tag for
  # @param tag [String] the administrative tag to delete
  # @return [AdministrativeTag] the tag instance
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def destroy(tag:)
    populate_legacy_tags_if_empty!

    AdministrativeTag.find_by!(druid: item.pid, tag: tag).destroy
  end

  private

  attr_reader :item

  def legacy_tags
    item.identityMetadata.ng_xml.search('//tag').map(&:content)
  end

  def populate_legacy_tags_if_empty!
    return if AdministrativeTag.where(druid: item.pid).any?

    legacy_tags.each do |tag|
      AdministrativeTag.create(druid: item.pid, tag: tag)
    end
  end
end

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

  # @param item [Dor::Item] the item to list administrative tags for
  def initialize(item:)
    @item = item
  end

  # @return [Array<String>] an array of tags (strings), possibly empty
  def for
    AdministrativeTag.where(druid: item.pid).pluck(:tag).presence || legacy_tags
  end

  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @return [Array<AdministrativeTag>]
  def create(tags:)
    populate_legacy_tags_if_empty!
    tags.map { |tag| AdministrativeTag.create(druid: item.pid, tag: tag) }
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

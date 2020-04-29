# frozen_string_literal: true

# Shows and creates administrative tags.
class AdministrativeTags
  # Retrieve the administrative tags for an item
  #
  # @param item [Dor::Item] the item to list administrative tags for
  # @return [Array<String>] an array of tag strings (possibly empty)
  def self.for(item:)
    new(item: item).for
  end

  # Retrieve the content type tag for an item
  #
  # @param item [Dor::Item] the item to get the content type of
  # @return [Array<String>] an array of tag strings (possibly empty)
  def self.content_type(item:)
    new(item: item).content_type
  end

  # Retrieve the project tag for an item
  #
  # @param item [Dor::Item] the item to get the project of
  # @return [Array<String>] an array of tag strings (possibly empty)
  def self.project(item:)
    new(item: item).project
  end

  # Add one or more administrative tags for an item
  #
  # @param item [Dor::Item]  the item to create administrative tag(s) for
  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @param replace [Boolean] replace current tags? default: false
  # @return [Array<AdministrativeTag>]
  def self.create(item:, tags:, replace: false)
    new(item: item).create(tags: tags, replace: replace)
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
    AdministrativeTag.where(druid: item.pid).pluck(:tag)
  end

  # @return [Array<String>] an array of tags (strings), possibly empty
  def content_type
    AdministrativeTag
      .where(druid: item.pid)
      .where(tags_relation.matches('Process : Content Type : %'))
      .limit(1) # "THERE CAN BE ONLY ONE!"
      .pluck(:tag)
      .map { |tag| tag.split(' : ').last }
  end

  # @return [Array<String>] an array of tags (strings), possibly empty
  def project
    AdministrativeTag
      .where(druid: item.pid)
      .where(tags_relation.matches('Project : %'))
      .limit(1) # "THERE CAN BE ONLY ONE!"
      .pluck(:tag)
      .map { |tag| tag.split(' : ', 2).last }
  end

  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @param replace [Boolean] replace current tags? default: false
  # @return [Array<AdministrativeTag>]
  # @raise [ActiveRecord::RecordInvalid] if any druid/tag rows are duplicates
  def create(tags:, replace: false)
    ActiveRecord::Base.transaction do
      AdministrativeTag.where(druid: item.pid).destroy_all if replace

      tags.map do |tag|
        AdministrativeTag.create!(druid: item.pid, tag: tag)
      end
    end
  end

  # Update an administrative tag for an item
  #
  # @param current [String] the current administrative tag
  # @param new [String] the replacement administrative tag
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  # @raise [ActiveRecord::RecordInvalid] if any druid/tag rows are duplicates
  def update(current:, new:)
    AdministrativeTag.find_by!(druid: item.pid, tag: current).update!(tag: new)
  end

  # Destroy an administrative tag for an item
  #
  # @param item [Dor::Item]  the item to delete an administrative tag for
  # @param tag [String] the administrative tag to delete
  # @return [AdministrativeTag] the tag instance
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def destroy(tag:)
    AdministrativeTag.find_by!(druid: item.pid, tag: tag).destroy!
  end

  private

  attr_reader :item

  def tags_relation
    AdministrativeTag.arel_table[:tag]
  end
end

# frozen_string_literal: true

# Shows and creates administrative tags.
class AdministrativeTags
  # Retrieve the administrative tags for an item
  #
  # @param pid [String] the item identifier to list administrative tags for
  # @return [Array<String>] an array of tag strings (possibly empty)
  def self.for(pid:)
    new(pid: pid).for
  end

  # Retrieve the content type tag for an item
  #
  # @param pid [String] the item identifier to list administrative tags for
  # @return [Array<String>] an array of tag strings (possibly empty)
  def self.content_type(pid:)
    new(pid: pid).content_type
  end

  # Retrieve the project tag for an item
  #
  # @param pid [String] the item identifier to list administrative tags for
  # @return [Array<String>] an array of tag strings (possibly empty)
  def self.project(pid:)
    new(pid: pid).project
  end

  # Add one or more administrative tags for an item
  #
  # @param pid [String] the item identifier to list administrative tags for
  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @param replace [Boolean] replace current tags? default: false
  # @return [Array<AdministrativeTag>]
  def self.create(pid:, tags:, replace: false)
    new(pid: pid).create(tags: tags, replace: replace)
  end

  # Update an administrative tag for an item
  #
  # @param pid [String] the item identifier to list administrative tags for
  # @param current [String] the current administrative tag
  # @param new [String] the replacement administrative tag
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def self.update(pid:, current:, new:)
    new(pid: pid).update(current: current, new: new)
  end

  # Destroy an administrative tag for an item
  #
  # @param pid [String] the item identifier to list administrative tags for
  # @param tag [String] the administrative tag to delete
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def self.destroy(pid:, tag:)
    new(pid: pid).destroy(tag: tag)
  end

  # @param pid [String] the item identifier to list administrative tags for
  def initialize(pid:)
    @pid = pid
  end

  # @return [Array<String>] an array of tags (strings), possibly empty
  def for
    AdministrativeTag.includes(:tag_label).where(druid: pid).pluck(:tag)
  end

  # @return [Array<String>] an array of tags (strings), possibly empty
  def content_type
    AdministrativeTag.includes(:tag_label)
                     .where(druid: pid, tag_label: TagLabel.content_type)
                     .limit(1) # "THERE CAN BE ONLY ONE!"
                     .pluck(:tag)
                     .map { |tag| tag.split(' : ').last }
  end

  # @return [Array<String>] an array of tags (strings), possibly empty
  def project
    AdministrativeTag.includes(:tag_label)
                     .where(druid: pid, tag_label: TagLabel.project)
                     .limit(1) # "THERE CAN BE ONLY ONE!"
                     .pluck(:tag)
                     .map { |tag| tag.split(' : ', 2).last }
  end

  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @param replace [Boolean] replace current tags? default: false
  # @return [Array<AdministrativeTag>]
  def create(tags:, replace: false)
    ActiveRecord::Base.transaction do
      AdministrativeTag.where(druid: pid).destroy_all if replace

      tags.map do |tag|
        # This is not atomic, so a race condition could occur here.
        tag_label = TagLabel.find_or_create_by!(tag: tag)

        AdministrativeTag.find_or_create_by!(druid: pid, tag_label: tag_label)
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # This catches the exception triggered by the race condition because find_or_create_by is not atomic.
    # If two threads are creating the same tag, one will get an exception.
    # We must catch this outside the transaction block, because once a constraint
    # is violated, PG will permit no more statements in that transaction.

    retry
  end

  # Update an administrative tag for an item
  #
  # @param current [String] the current administrative tag
  # @param new [String] the replacement administrative tag
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  # @raise [ActiveRecord::RecordInvalid] if any druid/tag rows are duplicates
  def update(current:, new:)
    ActiveRecord::Base.transaction do
      old_label = TagLabel.find_by!(tag: current)
      AdministrativeTag.find_by!(druid: pid, tag_label: old_label)
                       .update!(tag_label: TagLabel.find_or_create_by!(tag: new))
      old_label.destroy! if old_label.administrative_tags.count.zero?
    end
  end

  # Destroy an administrative tag for an item
  #
  # @param tag [String] the administrative tag to delete
  # @return [AdministrativeTag] the tag instance
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def destroy(tag:)
    ActiveRecord::Base.transaction do
      old_label = TagLabel.find_by!(tag: tag)
      AdministrativeTag.find_by!(druid: pid, tag_label: old_label).destroy!
      old_label.destroy! if old_label.administrative_tags.count.zero?
    end
  end

  private

  attr_reader :pid

  def tags_relation
    AdministrativeTag.arel_table[:tag]
  end
end

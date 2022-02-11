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

  # Destroy all administrative tags for an item
  #
  # @param pid [String] the item identifier to list administrative tags for
  # @return [Boolean] true if successful
  def self.destroy_all(pid:)
    new(pid: pid).destroy_all
  end

  # @param pid [String] the item identifier to list administrative tags for
  def initialize(pid:)
    @pid = pid
    @retry_count = 0
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
    # This catches the exception triggered by the race condition because find_or_create_by! is not atomic.
    # If two threads are creating the same tag, one will get an exception.
    # We must catch this outside the transaction block, because once a constraint
    # is violated, PG will permit no more statements in that transaction.
    # When we go to rails 6 we can replace find_or_create_by with create_or_find_by: https://sikac.hu/use-create-or-find-by-to-avoid-race-condition-in-rails-6-0-f44fca97d16b

    @retry_count += 1
    raise if @retry_count > 5

    Rails.logger.warn("Possible race condition creating tags: #{tags}.  This should only happen one time, otherwise this might be an error")
    sleep(@retry_count)
    retry
  end

  # Update an administrative tag for an item
  #
  # @param current [String] the current administrative tag
  # @param new [String] the replacement administrative tag
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  # @raise [ActiveRecord::RecordNotUnique] if any druid/tag rows are duplicates
  def update(current:, new:)
    ActiveRecord::Base.transaction do
      old_label = TagLabel.find_by!(tag: current)
      AdministrativeTag.find_by!(druid: pid, tag_label: old_label)
                       .update!(tag_label: TagLabel.find_or_create_by!(tag: new))
      old_label.destroy! if old_label.administrative_tags.count.zero?
    end
  rescue ActiveRecord::RecordNotUnique
    # This catches the exception triggered by the race condition because find_or_create_by! is not atomic.
    # If two threads are creating the same tag, one will get an exception.
    # We must catch this outside the transaction block, because once a constraint
    # is violated, PG will permit no more statements in that transaction.
    # When we go to rails 6 we can replace find_or_create_by with create_or_find_by: https://sikac.hu/use-create-or-find-by-to-avoid-race-condition-in-rails-6-0-f44fca97d16b

    @retry_count += 1
    raise if @retry_count > 5

    Rails.logger.warn("Possible race condition updating tag: #{current} with #{new}.  This should only happen one time, otherwise this might be an error")
    sleep(@retry_count)
    retry
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

  def destroy_all
    self.for.each { |tag| destroy(tag: tag) }
  end

  private

  attr_reader :pid

  def tags_relation
    AdministrativeTag.arel_table[:tag]
  end
end

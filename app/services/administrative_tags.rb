# frozen_string_literal: true

# Shows and creates administrative tags.
class AdministrativeTags
  # Retrieve the administrative tags for an item
  #
  # @param identifier [String] the item identifier to list administrative tags for
  # @return [Array<String>] an array of tag strings (possibly empty)
  def self.for(identifier:)
    new(identifier:).for
  end

  # Retrieve the content type tag for an item
  #
  # @param identifier [String] the item identifier to list administrative tags for
  # @return [Array<String>] an array of tag strings (possibly empty)
  def self.content_type(identifier:)
    new(identifier:).content_type
  end

  # Retrieve the project tag for an item
  #
  # @param identifier [String] the item identifier to list administrative tags for
  # @return [Array<String>] an array of tag strings (possibly empty)
  def self.project(identifier:)
    new(identifier:).project
  end

  # Add one or more administrative tags for an item
  #
  # @param identifier [String] the item identifier to list administrative tags for
  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @param replace [Boolean] replace current tags? default: false
  # @return [Array<AdministrativeTag>]
  def self.create(identifier:, tags:, replace: false)
    new(identifier:).create(tags:, replace:)
  end

  # Update an administrative tag for an item
  #
  # @param identifier [String] the item identifier to list administrative tags for
  # @param current [String] the current administrative tag
  # @param new [String] the replacement administrative tag
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def self.update(identifier:, current:, new:)
    new(identifier:).update(current:, new:)
  end

  # Destroy an administrative tag for an item
  #
  # @param identifier [String] the item identifier to list administrative tags for
  # @param tag [String] the administrative tag to delete
  # @return [Boolean] true if successful
  # @raise [ActiveRecord::RecordNotFound] if row not found for druid/tag combination
  def self.destroy(identifier:, tag:)
    new(identifier:).destroy(tag:)
  end

  # Destroy all administrative tags for an item
  #
  # @param identifier [String] the item identifier to list administrative tags for
  # @return [Boolean] true if successful
  def self.destroy_all(identifier:)
    new(identifier:).destroy_all
  end

  # @param identifier [String] the item identifier to list administrative tags for
  def initialize(identifier:)
    @identifier = identifier
    @retry_count = 0
  end

  # @return [Array<String>] an array of tags (strings), possibly empty
  def for
    AdministrativeTag.includes(:tag_label).where(druid: identifier).pluck(:tag)
  end

  # @return [Array<String>] an array of tags (strings), possibly empty
  def project
    AdministrativeTag.includes(:tag_label)
                     .where(druid: identifier, tag_label: TagLabel.project)
                     .limit(1) # "THERE CAN BE ONLY ONE!"
                     .pluck(:tag)
                     .map { |tag| tag.split(' : ', 2).last }
  end

  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @param replace [Boolean] replace current tags? default: false
  # @return [Array<AdministrativeTag>]
  def create(tags:, replace: false)
    ActiveRecord::Base.transaction do
      AdministrativeTag.where(druid: identifier).destroy_all if replace

      tags.map do |tag|
        # This is not atomic, so a race condition could occur here.
        tag_label = TagLabel.find_or_create_by!(tag:)

        AdministrativeTag.find_or_create_by!(druid: identifier, tag_label:)
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

    Rails.logger.warn("Possible race condition creating tags: #{tags}. " \
                      'This should only happen one time, otherwise this might be an error')
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
      AdministrativeTag.find_by!(druid: identifier, tag_label: old_label)
                       .update!(tag_label: TagLabel.find_or_create_by!(tag: new))
      old_label.destroy! if old_label.administrative_tags.none?
    end
  rescue ActiveRecord::RecordNotUnique
    # This catches the exception triggered by the race condition because find_or_create_by! is not atomic.
    # If two threads are creating the same tag, one will get an exception.
    # We must catch this outside the transaction block, because once a constraint
    # is violated, PG will permit no more statements in that transaction.
    # When we go to rails 6 we can replace find_or_create_by with create_or_find_by: https://sikac.hu/use-create-or-find-by-to-avoid-race-condition-in-rails-6-0-f44fca97d16b

    @retry_count += 1
    raise if @retry_count > 5

    Rails.logger.warn("Possible race condition updating tag: #{current} with #{new}. " \
                      'This should only happen one time, otherwise this might be an error')
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
      old_label = TagLabel.find_by!(tag:)
      AdministrativeTag.find_by!(druid: identifier, tag_label: old_label).destroy!
      old_label.destroy! if old_label.administrative_tags.none?
    end
  end

  def destroy_all
    self.for.each { |tag| destroy(tag:) }
  end

  private

  attr_reader :identifier
end

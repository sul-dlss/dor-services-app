# frozen_string_literal: true

# Finds the members of a collection
class MemberService
  # @param [String] druid the identifier of the collection
  # @param [Boolean] publishable when true, restrict to publishable items only
  # @return [Array<String>] the druids for the members of this collection
  def self.for(druid, publishable: false)
    new(druid, publishable:).for
  end

  def initialize(druid, publishable: false)
    @druid = druid
    @publishable = publishable
  end

  def for
    RepositoryObject
      .currently_members_of_collection(druid)
      .then { |members| only_publishable? ? members.select(&:publishable?) : members }
      .pluck(:external_identifier)
  end

  private

  attr_reader :druid

  def only_publishable?
    @publishable
  end
end

# frozen_string_literal: true

# Finds the members of a collection by using Solr
class MemberService
  # @param [String] druid the identifier of the collection
  # @param [Boolean] only_published when true, restrict to only published items
  # @param [Boolean] exclude_opened when true, exclude opened items
  # @return [Array<String>] the druids for the members of this collection
  def self.for(druid, only_published: false, exclude_opened: false)
    new(druid, only_published:, exclude_opened:).for
  end

  def initialize(druid, only_published: false, exclude_opened: false)
    @druid = druid
    @only_published = only_published
    @exclude_opened = exclude_opened
  end

  def for
    Dro.members_of_collection(druid).select(:external_identifier, :version)
       .then { |members| exclude_opened_members(members) }
       .then { |members| only_published_members(members) }
       .map(&:external_identifier)
  end

  private

  attr_reader :druid, :only_published, :exclude_opened

  def exclude_opened_members(members)
    return members unless exclude_opened

    members.reject do |member|
      workflow_client.active_lifecycle(druid: member.external_identifier, milestone_name: 'opened', version: member.version.to_s).present?
    end
  end

  def only_published_members(members)
    return members unless only_published

    members.select do |member|
      workflow_client.lifecycle(druid: member.external_identifier, milestone_name: 'published', version: member.version).present?
    end
  end

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end

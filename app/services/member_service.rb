# frozen_string_literal: true

# Finds the members of a collection
class MemberService
  # @param [String] druid the identifier of the collection
  # @param [Boolean] only_published when true, restrict to only published items
  # @param [Boolean] exclude_opened when true, exclude opened items
  # @return [Array<Hash<String,String>>] the members of this collection
  def self.for(druid, only_published: false, exclude_opened: false)
    Dro
      .members_of_collection(druid)
      .then { |members| reject_opened_members(members, exclude_opened) }
      .then { |members| select_published_members(members, only_published) }
      .map do |member|
      {
        'id' => member.external_identifier,
        'objectType' => member.content_type == Cocina::Models::ObjectType.agreement ? 'agreement' : 'item'
      }
    end
  end

  def self.reject_opened_members(members, exclude_opened)
    return members unless exclude_opened

    members.reject do |member|
      WorkflowClientFactory.build.status(druid: member.external_identifier, version: member.version).display_simplified == 'Opened'
    end
  end

  def self.select_published_members(members, only_published)
    return members unless only_published

    members.select do |member|
      WorkflowClientFactory.build.lifecycle(druid: member.external_identifier, milestone_name: 'published', version: member.version).present?
    end
  end
end

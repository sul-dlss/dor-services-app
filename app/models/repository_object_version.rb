# frozen_string_literal: true

# Models a repository object as it looked at a particular version.
class RepositoryObjectVersion < ApplicationRecord
  belongs_to :repository_object

  scope :in_virtual_objects, ->(member_druid) { where("structural #> '{hasMemberOrders,0}' -> 'members' ? :druid", druid: member_druid) }
  scope :members_of_collection, ->(collection_druid) { where("structural -> 'isMemberOf' ? :druid", druid: collection_druid) }

  validates :version, :version_description, presence: true
end

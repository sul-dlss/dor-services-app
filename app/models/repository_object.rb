# frozen_string_literal: true

# Models a repository object (item, collection, or admin policy)
class RepositoryObject < ApplicationRecord
  has_many :repository_object_versions, dependent: :destroy
  belongs_to :head, class_name: 'RepositoryObjectVersion', optional: true
  belongs_to :open, class_name: 'RepositoryObjectVersion', optional: true

  validates :external_identifier, :type, presence: true
  enum :type, %i[dro admin_policy collection].index_with(&:to_s), validate: true
end

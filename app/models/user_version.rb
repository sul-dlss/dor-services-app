# frozen_string_literal: true

# Models a user version of a specific repository object version.
class UserVersion < ApplicationRecord
  belongs_to :repository_object_version

  validate :repository_object_version_is_closed

  def repository_object_version_is_closed
    # Validate that the repository object version is closed
    errors.add(:repository_object_version, 'cannot set a user version to an open RepositoryObjectVersion') if repository_object_version.open?
  end
end

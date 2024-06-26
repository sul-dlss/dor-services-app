# frozen_string_literal: true

# Models a user version of a specific repository object version.
class UserVersion < ApplicationRecord
  belongs_to :repository_object_version
  before_save :set_version

  validate :repository_object_version_is_closed
  validate :repository_object_version_has_cocina

  def repository_object_version_is_closed
    # Validate that the repository object version is closed
    errors.add(:repository_object_version, 'cannot set a user version to an open RepositoryObjectVersion') if repository_object_version.open?
  end

  def repository_object_version_has_cocina
    # Validate that the repository object version has cocina (lecacy versions may not)
    errors.add(:repository_object_version, 'cannot set a user version to an RepositoryObjectVersion without cocina') unless repository_object_version.has_cocina?
  end

  def as_json
    {
      userVersion: version,
      version: repository_object_version.version,
      withdrawn:
    }
  end

  private

  def set_version
    self.version = repository_object_version.user_versions.maximum(:version).to_i + 1 unless version
  end
end

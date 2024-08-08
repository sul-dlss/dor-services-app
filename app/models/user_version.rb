# frozen_string_literal: true

# Models a user version of a specific repository object version.
class UserVersion < ApplicationRecord
  belongs_to :repository_object_version
  before_save :set_version

  enum :state, withdrawn: 'withdrawn', available: 'available', permanently_withdrawn: 'permanently_withdrawn'

  validate :repository_object_version_is_closed
  validate :repository_object_version_has_cocina
  validate :can_withdraw
  validate :when_permanently_withdrawn

  def repository_object_version_is_closed
    # Validate that the repository object version is closed
    errors.add(:repository_object_version, 'cannot set a user version to an open RepositoryObjectVersion') if repository_object_version.open?
  end

  def repository_object_version_has_cocina
    # Validate that the repository object version has cocina (legacy versions may not)
    errors.add(:repository_object_version, 'cannot set a user version to an RepositoryObjectVersion without cocina') unless repository_object_version.has_cocina?
  end

  def can_withdraw
    # Validate that the user version can be withdrawn or restored
    errors.add(:repository_object_version, 'head version cannot be withdrawn') if withdrawn? && (head? || version.nil?)
  end

  def when_permanently_withdrawn
    # Validate that the user version state cannot be changed from permanently withdrawn
    errors.add(:repository_object_version, 'cannot set user version state when permanently withdrawn') if changed_attributes['state'] == 'permanently_withdrawn'
  end

  def as_json
    {
      userVersion: version,
      version: repository_object_version.version,
      withdrawn: withdrawn?,
      withdrawable: withdrawable?,
      restorable: restorable?,
      head: head?
    }
  end

  def withdrawable?
    available? && !head?
  end

  def restorable?
    withdrawn?
  end

  def head?
    version == head_version
  end

  private

  def set_version
    self.version = head_version.to_i + 1 unless version
  end

  def head_version
    repository_object_version.repository_object.head_user_version
  end
end

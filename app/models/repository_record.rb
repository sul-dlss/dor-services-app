# frozen_string_literal: true

# Depends on the child class having an external_identifier and lock columns.
class RepositoryRecord < ApplicationRecord
  self.abstract_class = true
  self.locking_column = 'lock'

  def external_lock
    # This should be opaque, but this makes troubeshooting easier.
    # The external_identifier is included so that there is enough entropy such
    # that the lock can't be used for an object it doesn't belong to as the
    # lock column is just an integer sequence.
    [external_identifier, lock.to_s].join('=')
  end
end

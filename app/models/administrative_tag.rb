# frozen_string_literal: true

# Administrative tags for an object
class AdministrativeTag < ApplicationRecord
  validates :tag, format: {
    with: /\A.+( : .+)+\z/,
    message: 'must be a series of 2 or more strings delimited with space-padded colons, e.g., "Registered By : mjgiarlo : now"'
  }, uniqueness: {
    scope: :druid,
    message: 'has already been assigned to the given druid (no duplicate tags for a druid)'
  }
end
